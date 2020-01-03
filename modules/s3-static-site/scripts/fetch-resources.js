const https = require('https');
const { promises: fsp, readFileSync } = require('fs');
const path = require('path');
const crypto = require('crypto');
const os = require('os');

const createHash = () => crypto.createHash('sha1').update(`${Date.now()}${Math.random()}`).digest('hex').substr(0, 5);

const downloadDeployable = (url, destination) => new Promise((resolve, reject) => {
    https.get(url, response => {
        if ([301, 302].includes(response.statusCode)) {
            return downloadFile(url, destination).then(resolve).catch(reject);
        }
        if (response.statusCode !== 200) {
            return reject(response.statusMessage);
        }
        fs.createReadStream(destination).pipe(response).on('end', resolve);
    });
});

const main = async ({ deployableName, owner, repo, version }) => {
    const targetDir = path.join(os.tmpdir(), createHash());
    const targetPath = path.join(targetDir, createHash());

    await fsp.mkdir(targetPath, { recursive: true });
}

main(JSON.parse(readFileSync(0))) // read and parse args from stdin
    .catch(err => {
        console.error(err);
        process.exit(1);
    });
