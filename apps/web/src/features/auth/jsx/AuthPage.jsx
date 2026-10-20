// Purpose: Switches between the traveler Login and Signup forms within the /auth page.
import React, { useState } from 'react';
import Login from './Login';
import Signup from './Signup';

const AuthPage = () => {
  const [showLogin, setShowLogin] = useState(true);

  return (
    <>
      {showLogin ? (
        <Login 
          onSwitchToSignup={() => setShowLogin(false)}
        />
      ) : (
        <Signup 
          onSwitchToLogin={() => setShowLogin(true)}
        />
      )}
    </>
  );
};

export default AuthPage;
