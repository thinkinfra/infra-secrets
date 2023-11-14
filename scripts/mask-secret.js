const core = require('@actions/core');

const secret = process.env.PLAIN_TEXT_SECRET;
core.setSecret(secret);

console.log('Secret is masked in the logs');