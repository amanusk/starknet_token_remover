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

pub async fn set_recipient() -> Result<()> {
    let envfile = EnvFile::new(&Path::new(".env"))?;

    let provider = JsonRpcClient::new(HttpTransport::new(
        Url::parse(envfile.get("STARKNET_RPC_URL").unwrap()).unwrap(),
    ));
    let chain_id = provider.chain_id().await.unwrap();

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

    let recipient = FieldElement::from_hex_be(
        "0x0563b71ac29b54Ef78bbFDb3FBf0338441d3948C573621E7824f9dBc1Ce23d56",
    )
    .unwrap();

    let set_recipient_call = Call {
        to: remover_address,
        selector: get_selector_from_name("set_destination").unwrap(),
        calldata: vec![recipient],
    };

    let result = account
        .execute(vec![set_recipient_call])
        .send()
        .await
        .unwrap();

    println!(
        "Recipient set to {:#064x} in Tx: {:#064x}",
        recipient, result.transaction_hash
    );

    Ok(())
}
