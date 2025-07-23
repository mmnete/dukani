import 'package:flutter/material.dart';
import 'dart:async'; // For Timer
import '../../models/models.dart';
import '../../services/api_provider.dart';
import '../../services/user_session_provider.dart';

// This is the OnboardingScreen component to be used in your main file.
class OnboardingScreen extends StatefulWidget {
  final UserSessionProvider sessionProvider;
  final ApiProvider apiService; // New: Accept ApiProvider
  final String initialStep; // New parameter to set initial step

  const OnboardingScreen({
    super.key,
    required this.sessionProvider,
    required this.apiService, // Initialize apiService
    this.initialStep = 'intro', // Default to 'intro'
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _step = 'intro';
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopAddressController = TextEditingController();
  final TextEditingController _managerNameController = TextEditingController(); // For manager registration
  final TextEditingController _workerFullNameController = TextEditingController(); // For worker full name
  final TextEditingController _inviteCodeController = TextEditingController(); // For worker joining via invite

  // File? _profilePhoto; // For optional photo upload (uncomment if implementing)
  // final ImagePicker _picker = ImagePicker(); // For optional photo upload (uncomment if implementing)

  bool _isScreenLoading = false; // Separate loading state for screen actions
  String _screenError = ''; // Separate error for screen-specific messages
  Timer? _resendTimerCountdown;
  int _resendTimerValue = 0;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep; // Set initial step from widget parameter

    // Listen to provider's loading and error states
    widget.sessionProvider.addListener(_onSessionProviderChange);
  }

  @override
  void dispose() {
    _resendTimerCountdown?.cancel();
    _phoneNumberController.dispose();
    _otpController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _managerNameController.dispose();
    _workerFullNameController.dispose();
    _inviteCodeController.dispose();
    widget.sessionProvider.removeListener(_onSessionProviderChange);
    super.dispose();
  }

  void _onSessionProviderChange() {
    setState(() {
      _isScreenLoading = widget.sessionProvider.isLoading;
      _screenError = widget.sessionProvider.authError ?? '';

      // If code was sent, navigate to OTP verification step
      if (widget.sessionProvider.verificationId != null && _step == 'phone_entry') {
        _step = 'otp_verification';
        _startResendTimer(); // Start OTP timer
      }
    });
  }

  void _startResendTimer() {
    _resendTimerCountdown?.cancel(); // Cancel any existing timer
    _resendTimerValue = 60; // Start from 60 seconds
    _resendTimerCountdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimerValue > 0) {
        setState(() {
          _resendTimerValue--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  // Initiates phone authentication process
  Future<void> _handlePhoneNumberSubmit() async {
    _screenError = '';
    if (_phoneNumberController.text.length < 9) {
      setState(() {
        _screenError = 'Please enter a valid Tanzanian phone number (e.g., 7XXXXXXXX)';
      });
      return;
    }
    // Firebase expects full international format, e.g., "+2557XXXXXXXX"
    final String fullPhoneNumber = '+255${_phoneNumberController.text}';
    await widget.sessionProvider.initiatePhoneAuth(fullPhoneNumber);
    // The _onSessionProviderChange listener will handle step navigation on codeSent
  }

  // Completes sign-in with the provided OTP
  Future<void> _handleOtpVerification() async {
    _screenError = '';
    if (_otpController.text.length != 6) { // Firebase OTPs are typically 6 digits
      setState(() {
        _screenError = 'Please enter the 6-digit verification code.';
      });
      return;
    }
    final bool success = await widget.sessionProvider.signInWithPhoneNumber(_otpController.text);
    if (success) {
      // If sign-in is successful, the authStateChanges listener in UserSessionProvider
      // will update the state. The main app's Consumer will then check
      // if the user is new (userType == unknown) and redirect to role_selection
      // or directly to specific registration steps if initialStep was set.
      print('OTP verified. User signed in. Main app will handle redirection based on profile status.');
    } else {
      print('OTP verification failed.');
    }
  }

  // For optional photo upload (uncomment if implementing)
  // Future<void> _pickImage() async {
  //   final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
  //   if (pickedFile != null) {
  //     setState(() {
  //       _profilePhoto = File(pickedFile.path);
  //     });
  //   }
  // }

  // Common wrapper for content screens
  Widget _buildScreenWrapper({
    required Widget child,
    required String title,
    VoidCallback? onBack,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0FDF4), Color(0xFFE0F2FE)],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 10.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onBack != null)
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.grey),
                        onPressed: onBack,
                        tooltip: 'Go back',
                      ),
                    ),
                  const SizedBox(height: 16.0),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24.0),
                  child,
                  if (_screenError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        _screenError,
                        style: const TextStyle(color: Colors.red, fontSize: 14.0),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (widget.sessionProvider.authError != null && widget.sessionProvider.authError!.isNotEmpty)
                     Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        widget.sessionProvider.authError!,
                        style: const TextStyle(color: Colors.red, fontSize: 14.0),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget currentStepWidget;

    switch (_step) {
      case 'intro':
        currentStepWidget = _buildScreenWrapper(
          title: "Welcome to Dukani!",
          child: Column(
            children: [
              const SizedBox(height: 8.0),
              Text("Your Business, Simplified.", style: TextStyle(fontSize: 18.0, color: Colors.grey[600]), textAlign: TextAlign.center),
              const SizedBox(height: 8.0),
              Text("Effortless Stock Tracking.", style: TextStyle(fontSize: 18.0, color: Colors.grey[600]), textAlign: TextAlign.center),
              const SizedBox(height: 8.0),
              Text("Smart Decisions, Real Data.", style: TextStyle(fontSize: 18.0, color: Colors.grey[600]), textAlign: TextAlign.center),
              const SizedBox(height: 8.0),
              Text("Grow Your Business, Easily.", style: TextStyle(fontSize: 18.0, color: Colors.grey[600]), textAlign: TextAlign.center),
              const SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: _isScreenLoading ? null : () => setState(() => _step = 'phone_entry'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[500], foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                child: _isScreenLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Get Started'),
              ),
              const SizedBox(height: 16.0),
              TextButton(
                onPressed: _isScreenLoading ? null : () => setState(() => _step = 'phone_entry'),
                child: Text('Already have an account? Log In', style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        );
        break;

      case 'phone_entry':
        currentStepWidget = _buildScreenWrapper(
          title: "Enter Your Phone Number",
          onBack: () => setState(() => _step = 'intro'),
          child: Column(
            children: [
              Text("We'll send a verification code to this number.", style: TextStyle(color: Colors.grey[600], fontSize: 16.0), textAlign: TextAlign.center),
              const SizedBox(height: 24.0),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Text('+255', style: TextStyle(color: Colors.grey[500], fontSize: 18.0))),
                    Icon(Icons.phone, color: Colors.grey[400]),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: TextFormField(
                        controller: _phoneNumberController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(hintText: '7XXXXXXXX', border: InputBorder.none, isDense: true, counterText: '', contentPadding: EdgeInsets.symmetric(vertical: 12.0)),
                        maxLength: 9,
                        style: const TextStyle(fontSize: 18.0, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _isScreenLoading ? null : _handlePhoneNumberSubmit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600], foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                child: _isScreenLoading
                    ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)), SizedBox(width: 10), Text('Sending OTP...')])
                    : const Text('Continue'),
              ),
            ],
          ),
        );
        break;

      case 'otp_verification':
        currentStepWidget = _buildScreenWrapper(
          title: "Verify Your Number",
          onBack: _isScreenLoading ? null : () => setState(() { _step = 'phone_entry'; _resendTimerCountdown?.cancel(); _resendTimerValue = 0; _otpController.clear(); }),
          child: Column(
            children: [
              Text("Enter the 6-digit code sent to +255${_phoneNumberController.text}.", style: TextStyle(color: Colors.grey[600], fontSize: 16.0), textAlign: TextAlign.center),
              const SizedBox(height: 24.0),
              SizedBox(
                width: 150,
                child: TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.black87),
                  decoration: InputDecoration(hintText: '------', counterText: '', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0)), filled: true, fillColor: Colors.grey[50]),
                ),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _isScreenLoading ? null : _handleOtpVerification,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600], foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                child: _isScreenLoading
                    ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)), SizedBox(width: 10), Text('Verifying...')])
                    : const Text('Verify'),
              ),
              const SizedBox(height: 16.0),
              _resendTimerValue > 0
                  ? Text('Resend code in $_resendTimerValue s', style: TextStyle(color: Colors.grey[500], fontSize: 14.0))
                  : TextButton(onPressed: _isScreenLoading ? null : () { _handlePhoneNumberSubmit(); }, child: Text('Resend Code', style: TextStyle(color: Colors.blue[600], fontWeight: FontWeight.w500))),
            ],
          ),
        );
        break;

      case 'role_selection':
        currentStepWidget = _buildScreenWrapper(
          title: "Welcome to Dukani!",
          onBack: _isScreenLoading ? null : () => setState(() => _step = 'phone_entry'),
          child: Column(
            children: [
              Text("It looks like you're new here. How would you like to get started?", style: TextStyle(color: Colors.grey[600], fontSize: 16.0), textAlign: TextAlign.center),
              const SizedBox(height: 32.0),
              _buildRoleSelectionCard(
                icon: Icons.store,
                iconColor: Colors.purple[600]!,
                title: 'I am a Business Owner',
                subtitle: 'Manage your entire business operations.',
                onTap: _isScreenLoading ? null : () => setState(() => _step = 'register_owner_details'), // New step for owner details
                backgroundColor: Colors.purple[100]!,
              ),
              const SizedBox(height: 16.0),
              _buildRoleSelectionCard(
                icon: Icons.group,
                iconColor: Colors.teal[600]!,
                title: 'I am an Invited Worker',
                subtitle: 'Join your team\'s stock management.',
                onTap: _isScreenLoading ? null : () => setState(() => _step = 'enter_invite_code'), // New step for invite code
                backgroundColor: Colors.teal[100]!,
              ),
            ],
          ),
        );
        break;

      case 'register_owner_details':
        currentStepWidget = _buildScreenWrapper(
          title: "Register Your Business",
          onBack: _isScreenLoading ? null : () => setState(() => _step = 'role_selection'),
          child: Column(
            children: [
              Text("Provide details for your new shop.", style: TextStyle(color: Colors.grey[600], fontSize: 16.0), textAlign: TextAlign.center),
              const SizedBox(height: 24.0),
              TextFormField(
                controller: _shopNameController,
                decoration: const InputDecoration(hintText: 'Shop Name (e.g., Mama Amina Grocery)'),
                style: const TextStyle(fontSize: 18.0),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _shopAddressController,
                decoration: const InputDecoration(hintText: 'Shop Address (e.g., Kariakoo, Dar es Salaam)'),
                style: const TextStyle(fontSize: 18.0),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _managerNameController,
                decoration: const InputDecoration(hintText: 'Your Full Name (Manager)'),
                style: const TextStyle(fontSize: 18.0),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _isScreenLoading ? null : () async {
                  if (_shopNameController.text.isEmpty || _shopAddressController.text.isEmpty || _managerNameController.text.isEmpty) {
                    setState(() { _screenError = 'Please fill all fields.'; });
                    return;
                  }
                  if (widget.sessionProvider.userId == null) {
                    setState(() { _screenError = 'User not authenticated. Please restart the process.'; });
                    return;
                  }

                  setState(() { _isScreenLoading = true; _screenError = ''; });
                  final result = await widget.apiService.onboardShop(
                    name: _shopNameController.text,
                    address: _shopAddressController.text,
                    phoneNumber: '+255${_phoneNumberController.text}', // Use the phone from initial entry
                    managerFirebaseUid: widget.sessionProvider.userId!,
                  );
                  setState(() { _isScreenLoading = false; });

                  if (result['success']) {
                    final String newShopId = result['shop_id'];
                    // Update the Firebase profile with the manager role and new shop ID
                    final bool completeRegSuccess = await widget.sessionProvider.completeRegistration(
                      userType: UserType.manager,
                      name: _managerNameController.text,
                      phoneNumber: '+255${_phoneNumberController.text}',
                      shopId: newShopId,
                    );
                    if (completeRegSuccess) {
                      print('Shop and Manager profile completed!');
                      // The main app Consumer will detect userType change and navigate
                    } else {
                      setState(() { _screenError = widget.sessionProvider.authError ?? 'Failed to complete registration.'; });
                    }
                  } else {
                    setState(() { _screenError = result['error'] ?? 'Failed to onboard shop.'; });
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[600], foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                child: _isScreenLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create Business Account'),
              ),
            ],
          ),
        );
        break;

      case 'enter_invite_code':
        currentStepWidget = _buildScreenWrapper(
          title: "Join as Worker",
          onBack: _isScreenLoading ? null : () => setState(() => _step = 'role_selection'),
          child: Column(
            children: [
              Text("Enter the invitation code provided by your shop manager.", style: TextStyle(color: Colors.grey[600], fontSize: 16.0), textAlign: TextAlign.center),
              const SizedBox(height: 24.0),
              TextFormField(
                controller: _inviteCodeController,
                decoration: const InputDecoration(hintText: 'Invitation Code'),
                style: const TextStyle(fontSize: 18.0),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _isScreenLoading ? null : () async {
                  if (_inviteCodeController.text.isEmpty) {
                    setState(() { _screenError = 'Please enter an invitation code.'; });
                    return;
                  }
                  if (widget.sessionProvider.userId == null) {
                    setState(() { _screenError = 'User not authenticated. Please restart the process.'; });
                    return;
                  }

                  setState(() { _isScreenLoading = true; _screenError = ''; });
                  // Simulate validating invite code and getting shop ID from it
                  // In a real app, you'd call an API to validate the invite code
                  // and return the associated shopId and worker details.
                  final Map<String, dynamic> result = await widget.apiService.getShopDetails(_inviteCodeController.text); // Using invite code as shopId for dummy
                  setState(() { _isScreenLoading = false; });

                  if (result['success'] && result['shop'] != null) {
                    final Shop invitedShop = Shop.fromJson(result['shop']);
                    // Move to the next step to collect worker's full name and photo
                    setState(() {
                      _step = 'register_worker_details';
                    });
                  } else {
                    setState(() { _screenError = result['error'] ?? 'Invalid invitation code or shop not found.'; });
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[600], foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                child: _isScreenLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Next'),
              ),
            ],
          ),
        );
        break;

      case 'register_worker_details':
        currentStepWidget = _buildScreenWrapper(
          title: "Your Profile",
          onBack: _isScreenLoading ? null : () => setState(() => _step = 'enter_invite_code'),
          child: Column(
            children: [
              Text("Enter your full name and an optional photo.", style: TextStyle(color: Colors.grey[600], fontSize: 16.0), textAlign: TextAlign.center),
              const SizedBox(height: 24.0),
              // Optional Photo Upload (uncomment and implement if needed)
              // GestureDetector(
              //   onTap: _isScreenLoading ? null : _pickImage,
              //   child: CircleAvatar(
              //     radius: 60,
              //     backgroundColor: Colors.grey[200],
              //     backgroundImage: _profilePhoto != null ? FileImage(_profilePhoto!) : null,
              //     child: _profilePhoto == null
              //         ? Icon(Icons.camera_alt, size: 40, color: Colors.grey[600])
              //         : null,
              //   ),
              // ),
              // const SizedBox(height: 24.0),
              TextFormField(
                controller: _workerFullNameController,
                decoration: const InputDecoration(hintText: 'Your Full Name'),
                style: const TextStyle(fontSize: 18.0),
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _isScreenLoading ? null : () async {
                  if (_workerFullNameController.text.isEmpty) {
                    setState(() { _screenError = 'Please enter your full name.'; });
                    return;
                  }
                  if (widget.sessionProvider.userId == null) {
                    setState(() { _screenError = 'User not authenticated. Please restart the process.'; });
                    return;
                  }

                  setState(() { _isScreenLoading = true; _screenError = ''; });
                  // Complete registration as worker with the determined shop ID
                  final bool completeRegSuccess = await widget.sessionProvider.completeRegistration(
                    userType: UserType.worker,
                    name: _workerFullNameController.text,
                    phoneNumber: '+255${_phoneNumberController.text}',
                    shopId: _inviteCodeController.text, // Using invite code as shopId for dummy
                  );
                  setState(() { _isScreenLoading = false; });

                  if (completeRegSuccess) {
                    print('Worker profile completed!');
                    // The main app Consumer will detect userType change and navigate
                  } else {
                    setState(() { _screenError = widget.sessionProvider.authError ?? 'Failed to complete registration.'; });
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[600], foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                child: _isScreenLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Complete Registration'),
              ),
            ],
          ),
        );
        break;

      default: // This will catch the 'dashboard' step as well, which is handled by main app
        currentStepWidget = _buildScreenWrapper(
          title: "Success!",
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 24),
              const Text("You're all set!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text("Redirecting to your dashboard...", textAlign: TextAlign.center),
              const SizedBox(height: 32),
              ElevatedButton(onPressed: () async { await widget.sessionProvider.logoutUser(); }, child: const Text('Logout')),
            ],
          ),
        );
        break;
    }

    return Scaffold(body: currentStepWidget);
  }

  Widget _buildRoleSelectionCard({required IconData icon, required Color iconColor, required String title, required String subtitle, required VoidCallback? onTap, required Color backgroundColor}) {
    return Card(
      color: backgroundColor,
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0), side: BorderSide(color: iconColor.withOpacity(0.3), width: 1.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.0),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 60.0, color: iconColor),
              const SizedBox(height: 16.0),
              Text(title, style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: iconColor.darker()), textAlign: TextAlign.center),
              const SizedBox(height: 8.0),
              Text(subtitle, style: TextStyle(fontSize: 14.0, color: Colors.grey[700]), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

extension ColorShades on Color {
  Color darker([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
