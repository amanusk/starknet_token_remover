use token_remover::tests::mock_erc20::MockERC20;

use starknet::testing::set_caller_address;
use starknet::testing::set_block_timestamp;


use starknet::contract_address_const;
use starknet::get_block_info;
use starknet::ContractAddress;
use starknet::Felt252TryIntoContractAddress;
use starknet::TryInto;
use starknet::OptionTrait;
use box::BoxTrait;
use integer::u256;


use debug::PrintTrait;


const NAME: felt252 = 111;
const SYMBOL: felt252 = 222;


fn setup() -> (ContractAddress, u256) {
    let initial_supply: u256 = u256 { low: 1000000000_u128, high: 0_u128 };
    let account: ContractAddress = contract_address_const::<1>();
    // Set account as default caller
    set_caller_address(account);

    MockERC20::constructor(NAME, SYMBOL, initial_supply, account);
    (account, initial_supply)
}

#[test]
#[available_gas(1000000)]
fn test_constructor() {
    let initial_supply: u256 = u256 { low: 1000000000_u128, high: 0_u128 };
    let account: ContractAddress = contract_address_const::<1>();
    let decimals: u8 = 18_u8;

    MockERC20::constructor(NAME, SYMBOL, initial_supply, account);
    assert(MockERC20::total_supply() == initial_supply, 'Should eq initial_supply');
    assert(MockERC20::name() == NAME, 'Name should be NAME');
    assert(MockERC20::symbol() == SYMBOL, 'Symbol should be SYMBOL');
    assert(MockERC20::decimals() == decimals, 'Decimals should be 18');
}

#[test]
#[available_gas(1000000)]
fn test_get_balance() {
    let recipient: ContractAddress = 1.try_into().unwrap();
    let balance: u256 = u256 { low: 1000000000_u128, high: 0_u128 };
    MockERC20::constructor(1, 1, balance, recipient);
    assert(MockERC20::balance_of(recipient) == balance, 'Balance should be 0');
}

#[test]
#[available_gas(1000000)]
fn test_transfer() {
    let (account, initial_supply) = setup();
    let recipient: ContractAddress = contract_address_const::<2>();

    let amount: u256 = u256 { low: 1000_u128, high: 0_u128 };
    MockERC20::transfer(recipient, amount);
    assert(MockERC20::balance_of(account) == initial_supply - amount, 'Balance should be reduced');
    assert(MockERC20::balance_of(recipient) == amount, 'Balance be equal to amount');
}

fn get_timestamp() -> u64 {
    get_block_info().unbox().block_timestamp
}
