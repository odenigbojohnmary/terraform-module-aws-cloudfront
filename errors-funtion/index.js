const path = require('path');

exports.handler = (event, context, callback) => {
  const { request } = event.Records[0].cf;

  // Rewrite uri without extensions only
  // Will rewrite /blabla to /index.html but not /abc.txt or /xyz.css
  if (!path.extname(request.uri)) request.uri = '/index.html';

  callback(null, request);
};