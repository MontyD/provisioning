const path = require('path');
const {readFileSync, writeFileSync} = require('fs');

const contentTypes = require('./content-types.json');

const main = async (files) => {
    return Object.keys(files).reduce((acc, fileKey) => {
        const contentType = contentTypes[path.extname(files[fileKey])];
        if (!contentType) {
            throw new Error(`Could not find content type for file ${files[fileKey]}`);
        }
        acc[files[fileKey]] = contentType;
        return acc;
    }, {});
};

main(JSON.parse(readFileSync(0))) // read and parse args from stdin
    .then(contentTypes => process.stdout.write(JSON.stringify(contentTypes)))
    .catch(err => {
        console.error(err);
        process.exit(1);
    });