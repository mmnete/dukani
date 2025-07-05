Dukani Web App (React)
This is the web application for Dukani, built using React. This application can serve as a dashboard for managers or a public-facing interface.

🚀 How to Launch
Prerequisites:
Node.js (LTS version recommended)

npm or Yarn

Steps:
Navigate to the web_app directory:

cd path/to/your/dukani/web_app

Install dependencies:

npm install
# OR
yarn install

Start the development server:

npm start
# OR
yarn start

This will typically open the application in your browser at http://localhost:3000.

Configure Backend API URL:

You will need to configure your React app to point to your Django backend API (e.g., http://localhost:8000/api/). This is typically done via environment variables (e.g., a .env file) or a configuration file within your React project.

Example for a .env file (create web_app/.env):

REACT_APP_API_BASE_URL=http://localhost:8000/api/

Then, access it in your React code using process.env.REACT_APP_API_BASE_URL.

🧪 How to Run Unit Tests
Unit tests for the React web application are not yet set up in this MVP.