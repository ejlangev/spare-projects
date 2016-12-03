'use strict';

const aws = require('aws-sdk');

const MY_NUMBER = process.env.MY_NUMBER;
const TWILIO_NUMBER = process.env.TWILIO_NUMBER;
const S3_BUCKET = process.env.S3_BUCKET
const s3 = new aws.S3();

exports.handler = (event, context, callback) => {
  const now = new Date();
  const dailyFileName = `auto_text/${now.getFullYear()}-${now.getMonth() + 1}-${now.getDate()}.json`;
  const monthlyFileName = `auto_text/${now.getFullYear()}-${now.getMonth() + 1}.json`;
  const messageData = parseQuery(event['body-json'] || '');
  const fromNumber = messageData['From'];
  let numberToMatch = fromNumber;
  let body = messageData['Body'] || '';
  let destinationNumber = MY_NUMBER;

  if (fromNumber === MY_NUMBER) {
    const pieces = (body || '').split('::');

    if (pieces.length !== 2) {
      return context.succeed({
        statusCode: 200,
        body: 'Sorry I didn\'t understand that',
        to: MY_NUMBER,
       from: TWILIO_NUMBER
     });
    }

    numberToMatch = pieces[0].trim();
    body = pieces[1] || '';
    destinationNumber = numberToMatch;
  }

  body = body.replace(/\+/g, ' ');

    lookupS3JsonFile(dailyFileName)
        .catch(err => {
          console.log(err);
          return {};
        })
        .then(dailyPhoneNumberMap => {
          return dailyPhoneNumberMap[numberToMatch] ||
            lookupS3JsonFile(monthlyFileName).then(m => m[numberToMatch]);
        })
        .then(name => {
          // Send unknown name messages only to me
          if (!name) {
            destinationNumber = MY_NUMBER;
            body = `Unknown number ${numberToMatch}`;
          } else if (fromNumber !== MY_NUMBER) {
            destinationNumber = MY_NUMBER;
            body = `${name} (${numberToMatch}): ${body}`;
          }

          context.succeed({
            statusCode: 200,
            body: body,
            to: destinationNumber,
            from: TWILIO_NUMBER
          })
        })
        .catch(err => {
          context.fail({ statusCode: 400, error: JSON.stringify(error.message) })
        });
 };

function lookupS3JsonFile(filePath) {
  console.log(`Searching for ${filePath}`)
  return new Promise((resolve, reject) => {
    s3.getObject({
      Bucket: S3_BUCKET,
      Key: filePath
    }, function(error, data) {
      if (error) {
          return reject(error);
      }

      resolve(JSON.parse(data.Body.toString()));
    });
  });
}

function parseQuery(qstr) {
  var query = {};
  var a = qstr.substr(0).split('&');
  for (var i = 0; i < a.length; i++) {
    var b = a[i].split('=');
    query[decodeURIComponent(b[0])] = decodeURIComponent(b[1] || '');
  }
  return query;
}
