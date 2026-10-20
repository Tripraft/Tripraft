// Purpose: Composes the landing-page travel animation from local PNG illustrations and configured branding.
import React from 'react';
import GlobalConfig from '../../../config/globalConfig';
import '../css/AnimatedBackground.css';

const AnimatedBackground = () => {
  const appName = GlobalConfig.APP_NAME;

  return (
    <div className="animated-stage">
      <div className="animated-stars"></div>
      <div className="animated-horizon"></div>

      {/* Static URLs resolve under public/images; CSS controls each animation slot. */}
      {/* 1. Map */}
      <img 
        className="animated-sprite animated-map" 
        src="/images/map.png" 
        alt="map" 
      />
      
      {/* 2. Passport artwork in the animated-letsgo CSS slot. */}
      <img 
        className="animated-sprite animated-letsgo" 
        src="/images/passport.png" 
        alt="lets go" 
      />
      
      {/* 3. Traveller with Bag */}
      <img 
        className="animated-sprite animated-bagman" 
        src="/images/man.png" 
        alt="man with bag" 
      />
      
      {/* 4. Plane Takeoff */}
      <img 
        className="animated-sprite animated-plane" 
        src="/images/plane.png" 
        alt="plane" 
      />
      
      {/* 5. Tourist with Map */}
      <img 
        className="animated-sprite animated-tourist" 
        src="/images/travel_man.png" 
        alt="traveler with map" 
      />
      
      {/* 6. Confusion */}
      <img 
        className="animated-sprite animated-confuse" 
        src="/images/confuse_man.png" 
        alt="confusion" 
      />
      
      {/* 7. Search artwork in the animated-content CSS slot. */}
      <img 
        className="animated-sprite animated-content" 
        src="/images/search.png" 
        alt="content" 
      />
      
      {/* Brand Text - Dynamic from config */}
      <div className="animated-brand">{appName}</div>
      
      {/* 8. Planning artwork in the animated-happy CSS slot. */}
      <img 
        className="animated-sprite animated-happy" 
        src="/images/trip_plan.png" 
        alt="happy user" 
      />
      
      {/* 9. Celebration artwork in the animated-student CSS slot. */}
      <img 
        className="animated-sprite animated-student" 
        src="/images/happy.png" 
        alt="student" 
      />
    </div>
  );
};

export default AnimatedBackground;
