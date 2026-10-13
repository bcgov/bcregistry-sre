const url = format(DB_HOST, DB_NAME, DB_USER, DB_PASSWORD, DB_PORT)
execute: function (password, keySize, ivSize, salt) {
const { username, password, loginType } = getCredentials()
secretEnvVar(key: 'PASSWORD', secretName: "postman-e2e-secret", secretKey: 'password'),
