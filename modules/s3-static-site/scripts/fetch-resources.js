const https = require('https');
const path = require('path');
const crypto = require('crypto');

const { promises: fsp, readFileSync, createWriteStream } = require('fs');
const { exec } = require('child_process');

const contentTypes = require('./content-types.json');

const createHash = () => crypto.createHash('sha1').update(`${Date.now()}${Math.random()}`).digest('hex').replace(/[0-9]/g, '').substr(0, 5);

const runCommand = command => new Promise((resolve, reject) => {
    exec(command, (error, stdout, stderr) => {
        if (error || stderr) {
            return reject(error ? error.message : stderr);
        }
        return resolve(stdout);
    });
});

const mapFilesToContentType = (files, directoryPath) => {
    return files.reduce((acc, fileName) => {
        const contentType = contentTypes[path.extname(fileName)];
        if (!contentType) {
            throw new Error(`Unknown content type for file ${fileName}`);
        }
        acc[path.join(directoryPath, fileName)] = contentType;
        return acc;
    }, {});
};

const downloadDeployable = (url, destination) => new Promise((resolve, reject) => {
    https.get(url, response => {
        if ([301, 302].includes(response.statusCode)) {
            return downloadDeployable(response.headers.location, destination).then(resolve).catch(reject);
        }
        if (response.statusCode !== 200) {
            return reject(response.statusMessage);
        }
        response.pipe(createWriteStream(destination)).on('close', resolve);
    });
});

const main = async ({ deployableName, owner, repo, version }) => {
    const tempDir = path.join(__dirname, '.temp');
    const targetPath = path.join(tempDir, createHash());

    await runCommand(`rm -rf ${tempDir} && mkdir ${tempDir}`);
    await downloadDeployable(`https://github.com/${owner}/${repo}/releases/download/${version}/${deployableName}`, targetPath);

    await runCommand(`tar -xf ${targetPath} --force-local --directory  "${tempDir}"`);
    await fsp.unlink(targetPath);

    const content = await fsp.readdir(tempDir);
    if (content.length === 0) {
        throw new Error(`Empty deployable response`);
    }
    // single directory containing files
    if (content.length === 1 && (await fsp.stat(path.join(tempDir, content[0]))).isDirectory()) {
        return mapFilesToContentType(await fsp.readdir(path.join(tempDir, content[0])), path.join(tempDir, content[0]));
    }
    // many files at top level directory
    return mapFilesToContentType(content, tempDir);
}

main(JSON.parse(readFileSync(0))) // read and parse args from stdin
    .then(files => process.stdout.write(JSON.stringify(files)))
    .catch(err => {
        console.error(err);
        process.exit(1);
    });
