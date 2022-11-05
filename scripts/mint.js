require('dotenv').config();
const { createAlchemyWeb3 } = require('@alch/alchemy-web3');
const API_URL = process.env.API_URL;
const web3 = createAlchemyWeb3(API_URL);
const contract = require("../artifacts/contracts/ErgoNotes.sol/MyNFT.json")
const contractAddress = '0x0aECa5325bA95cE3E753db231251F4A1d9520815';
const nftContract = new web3.eth.Contract(contract.abi, contractAddress);

// 服务端
const express = require('express');
const bodyParser = require('body-parser');
const app = express();
app.use(
	bodyParser.urlencoded({
		extended: true,
	})
);
app.post('/mint', function (req, res, next) {
	let body = req.body;
    console.log('收到请求')
    console.log('body :',body);
	if (body['mint_type'] == 1) {
		mintNFT(
			'ipfs://QmZSxenUMZxKJKMGWoT2EadjCrwvBW2zrsRVHR57uWW5kh/0000000000000000000000000000000000000000000000000000000000000001.json',
            body['address']
		);
	} else if (body['mint_type'] == 2) {
		mintNFT(
			'ipfs://QmZSxenUMZxKJKMGWoT2EadjCrwvBW2zrsRVHR57uWW5kh/0000000000000000000000000000000000000000000000000000000000000002.json',
            body['address']
		);
	}
	res.send('okk');
});

app.listen(7070);

// 铸造
async function mintNFT(tokenURI,address) {
	const PUBLIC_KEY = process.env.PUBLIC_KEY;
	const PRIVATE_KEY = process.env.PRIVATE_KEY;
	const nonce = await web3.eth.getTransactionCount(PUBLIC_KEY, 'latest');
	const tx = {
		from: PUBLIC_KEY,
		to: contractAddress,
		nonce: nonce,
		gas: 500000,
		data: nftContract.methods.awardItem(address, tokenURI).encodeABI(),
	};

	const signPromise = web3.eth.accounts.signTransaction(tx, PRIVATE_KEY);
	signPromise
		.then((signedTx) => {
			web3.eth.sendSignedTransaction(signedTx.rawTransaction, function (err, hash) {
				if (!err) {
					console.log(
						'The hash of your transaction is: ',
						hash,
						"\nCheck Alchemy's Mempool to view the status of your transaction!"
					);
				} else {
					console.log('Something went wrong when submitting your transaction:', err);
				}
			});
		})
		.catch((err) => {
			console.log(' Promise failed:', err);
		});
}
