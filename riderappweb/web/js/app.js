firebase.auth().languageCode = "en";

var FirbasePhoneAuth = function (phoneNumber) {
  this.phoneNumber = phoneNumber;

  this.generateCaptcha = function () {
    window.recaptchaVerifier = new firebase.auth.RecaptchaVerifier("recaptcha", {
      size: "invisible",
      callback: function (response) {
        console.log("Done");
        return "ho gya";
      },
    });
  }

  this.sendOTP = function () {
    firebase
      .auth()
      .signInWithPhoneNumber(this.phoneNumber, window.recaptchaVerifier)
      .then(function (confirmationResult) {
        window.confirmationResult = confirmationResult;
        console.log("Code sent");
        return true;
      })
      .catch(function (error) {
        console.log(error);
        return false;
      });
  };

  this.verifyOTP = function (code) {
    try {
      let result = window.confirmationResult.confirm(code);
      let user = result.user;
      return user;
    } catch (e) {
      return null;
    }
  };
};

var Point = function (x, y) {
  this.x = x;
  this.y = y;
  this.distanceFrom = function (otherPoint) {
    return Math.sqrt(
      Math.pow(otherPoint.x - this.x, 2) + Math.pow(otherPoint.y - this.y, 2)
    );
  };
};
