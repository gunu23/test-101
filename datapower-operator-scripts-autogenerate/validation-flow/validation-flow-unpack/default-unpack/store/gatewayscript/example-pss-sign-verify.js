// Licensed Materials - Property of IBM
// IBM WebSphere DataPower Appliances
// Copyright IBM Corporation 2020. All Rights Reserved.
// US Government Users Restricted Rights - Use, duplication or disclosure
// restricted by GSA ADP Schedule Contract with IBM Corp.

const crypto = require('crypto');

try {

  var constants = {
    signingAlg: 'PS256',
    signingKey: 'name:Alice2048RSA',
    verifiyingCert: 'name:Alice2048RSA',
    msgToSign: 'Necessitas non habet legem'
  };

  // default MGF1 and saltlen
  // (viz. MGF1=hash used with signing alg and salt len = -1, i.e., salt len = hash len)
  var sign = crypto.createSign(constants.signingAlg);
  sign.update(constants.msgToSign).sign(constants.signingKey, function(error, signature) {
    if (error) {
      throw new Error(error);
    } else {
      signature = signature.toString('base64');
      var verify = crypto.createVerify(constants.signingAlg);
      verify.update(constants.msgToSign).verify(constants.verifiyingCert, signature, 'base64', function(error) {
        if (error) {
          throw new Error(error);
        } else {
          session.output.write(constants.msgToSign);
        }
      });
    }
  });

  sign = crypto.createSign(constants.signingAlg, undefined);
  sign.update(constants.msgToSign).sign(constants.signingKey, function(error, signature) {
    if (error) {
      throw new Error(error);
    } else {
      signature = signature.toString('base64');
      var verify = crypto.createVerify(constants.signingAlg);
      verify.update(constants.msgToSign).verify(constants.verifiyingCert, signature, 'base64', function(error) {
        if (error) {
          throw new Error(error);
        } else {
          session.output.write(constants.msgToSign);
        }
      });
    }
  });

  sign = crypto.createSign(constants.signingAlg, undefined, -1);
  sign.update(constants.msgToSign).sign(constants.signingKey, function(error, signature) {
    if (error) {
      throw new Error(error);
    } else {
      signature = signature.toString('base64');
      var verify = crypto.createVerify(constants.signingAlg);
      verify.update(constants.msgToSign).verify(constants.verifiyingCert, signature, 'base64', function(error) {
        if (error) {
          throw new Error(error);
        } else {
          session.output.write(constants.msgToSign);
        }
      });
    }
  });

  sign = crypto.createSign(constants.signingAlg, 'mgf1sha512');
  sign.update(constants.msgToSign).sign(constants.signingKey, function(error, signature) {
    if (error) {
      throw new Error(error);
    } else {
      signature = signature.toString('base64');
      var verify = crypto.createVerify(constants.signingAlg, 'mgf1sha512');
      verify.update(constants.msgToSign).verify(constants.verifiyingCert, signature, 'base64', function(error) {
        if (error) {
          throw new Error(error);
        } else {
          session.output.write(constants.msgToSign);
        }
      });
    }
  });

  sign = crypto.createSign(constants.signingAlg, undefined, 20);
  sign.update(constants.msgToSign).sign(constants.signingKey, function(error, signature) {
    if (error) {
      throw new Error(error);
    } else {
      signature = signature.toString('base64');
      var verify = crypto.createVerify(constants.signingAlg, undefined, 20);
      verify.update(constants.msgToSign).verify(constants.verifiyingCert, signature, 'base64', function(error) {
        if (error) {
          throw new Error(error);
        } else {
          session.output.write(constants.msgToSign);
        }
      });
    }
  });
} catch(e) {
  console.error("example-pss-sign-verify.js error: " + e);
  session.output.write("example-pss-sign-verify.js error: " + e);
}