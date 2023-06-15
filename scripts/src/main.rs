use clap::Parser;
use eyre::Result;

mod declare;
use declare::declare;

mod deploy;
use deploy::deploy;

mod approve;
use approve::approve;

mod set_recipient;
use set_recipient::set_recipient;

mod remove_tokens;
use remove_tokens::remove_tokens;

#[derive(Debug, Parser)]
#[clap(author, version, about)]
enum Action {
    #[clap(name = "declare")]
    Declare,
    #[clap(name = "deploy")]
    Deploy,
    #[clap(name = "approve")]
    Approve,
    #[clap(name = "set_recipient")]
    SetRecipient,
    #[clap(name = "remove_tokens")]
    RemoveTokens,
}

#[tokio::main]
async fn main() {
    if let Err(err) = run_command(Action::parse()).await {
        eprintln!("{}", format!("Error: {err}"));
        std::process::exit(1);
    }
}

async fn run_command(action: Action) -> Result<()> {
    match action {
        Action::Declare => declare().await,
        Action::Deploy => deploy().await,
        Action::Approve => approve().await,
        Action::SetRecipient => set_recipient().await,
        Action::RemoveTokens => remove_tokens().await,
    }
}
