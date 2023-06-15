use envfile::EnvFile;
use std::{path::Path, sync::Arc};
use url::Url;

use eyre::Result;
use starknet::{
    accounts::{Account, Call, SingleOwnerAccount},
    core::types::{BlockId, BlockTag, FieldElement},
    core::utils::get_selector_from_name,
    macros::felt,
    providers::{
        jsonrpc::{HttpTransport, JsonRpcClient},
        Provider,
    },
    signers::{LocalWallet, SigningKey},
};

pub async fn remove_tokens() -> Result<()> {
    let envfile = EnvFile::new(&Path::new(".env"))?;

    let provider = JsonRpcClient::new(HttpTransport::new(
        Url::parse(envfile.get("STARKNET_RPC_URL").unwrap()).unwrap(),
    ));
    let chain_id = provider.chain_id().await.unwrap();

    let dai_address = FieldElement::from_hex_be(
        "0x03e85bfbb8e2a42b7bead9e88e9a1b19dbccf661471061807292120462396ec9",
    )
    .unwrap();

    let usdc_address = FieldElement::from_hex_be(
        "0x005a643907b9a4bc6a55e9069c4fd5fd1f5c79a22470690f75556c4736e34426",
    )
    .unwrap();

    let remover_address = FieldElement::from_hex_be(
        "0x0134774cc62dd610ac2280730561e1462868c558c1e6ce56b046358a8610c7ef",
    )
    .unwrap();

    let signer = LocalWallet::from(SigningKey::from_secret_scalar(
        FieldElement::from_hex_be(envfile.get("PRIVATE_KEY").unwrap()).unwrap(),
    ));
    let address = FieldElement::from_hex_be(envfile.get("ACCOUNT_ADDRESS").unwrap()).unwrap();

    // TODO: set testnet/mainnet based on provider
    let mut account = SingleOwnerAccount::new(provider, signer, address, chain_id);

    // `SingleOwnerAccount` defaults to checking nonce and estimating fees against the latest
    // block. Optionally change the target block to pending with the following line:
    account.set_block_id(BlockId::Tag(BlockTag::Pending));

    let account = Arc::new(account);

    let remove_tokens_call = Call {
        to: remover_address,
        selector: get_selector_from_name("move_all").unwrap(),
        calldata: vec![
            FieldElement::from_dec_str("2").unwrap(),
            dai_address,
            FieldElement::from_dec_str("1").unwrap(),
            FieldElement::ZERO,
        ],
    };

    let result = account.execute(vec![remove_tokens_call]).send().await;
    // .unwrap();
    println!("Result {:#?}", result);

    // println!("Removing in Tx: {:#064x}", result.transaction_hash);

    Ok(())
}
