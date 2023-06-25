#[cfg(test)]
mod erc20_test {
    use starknet::testing::{set_caller_address, set_contract_address, set_block_timestamp};

    use token_remover::tests::mock_erc20::MockERC20;
    use token_remover::erc20::erc20::{IERC20Dispatcher, IERC20DispatcherTrait};

    use starknet::contract_address_const;
    use starknet::get_block_info;
    use starknet::ContractAddress;
    use starknet::Felt252TryIntoContractAddress;
    use starknet::SyscallResultTrait;
    use starknet::TryInto;
    use starknet::Into;

    use core::result::ResultTrait;
    use starknet::syscalls::{deploy_syscall, get_block_hash_syscall};
    use array::ArrayTrait;
    use option::OptionTrait;
    use starknet::class_hash::Felt252TryIntoClassHash;
    use serde::Serde;

    use box::BoxTrait;
    use integer::u256;


    use debug::PrintTrait;


    const NAME: felt252 = 111;
    const SYMBOL: felt252 = 222;


    fn setup() -> (ContractAddress, ContractAddress, u256) {
        let initial_supply: u256 = u256 { low: 1000000000_u128, high: 0_u128 };
        let account: ContractAddress = contract_address_const::<1>();
        // Set account as default caller
        set_caller_address(account);

        let mut calldata = ArrayTrait::new();
        NAME.serialize(ref calldata);
        SYMBOL.serialize(ref calldata);
        18.serialize(ref calldata);
        initial_supply.serialize(ref calldata);
        account.serialize(ref calldata);

        let (address0, _) = deploy_syscall(
            MockERC20::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
        )
            .unwrap();

        // MockERC20::constructor(NAME, SYMBOL, initial_supply, account);
        (address0, account, initial_supply)
    }

    #[test]
    #[available_gas(1000000)]
    fn test_constructor() {
        let initial_supply: u256 = u256 { low: 1000000000_u128, high: 0_u128 };
        let decimals: u8 = 18_u8;

        let (erc20_address, account, initial_supply) = setup();
        let mut erc20 = IERC20Dispatcher { contract_address: erc20_address };

        assert(erc20.total_supply() == initial_supply, 'Should eq initial_supply');
        assert(erc20.name() == NAME, 'Name should be NAME');
        assert(erc20.symbol() == SYMBOL, 'Symbol should be SYMBOL');
        assert(erc20.decimals() == decimals, 'Decimals should be 18');
    }

    #[test]
    #[available_gas(1000000)]
    fn test_get_balance() {
        let balance: u256 = u256 { low: 1000000000_u128, high: 0_u128 };
        let decimals: u8 = 18_u8;

        let (erc20_address, account, initial_supply) = setup();
        let mut erc20 = IERC20Dispatcher { contract_address: erc20_address };

        assert(erc20.balance_of(account) == balance, 'Balance should be 0');
    }

    #[test]
    #[available_gas(1000000)]
    fn test_transfer() {
        let (erc20_address, account, initial_supply) = setup();
        let mut erc20 = IERC20Dispatcher { contract_address: erc20_address };

        let recipient: ContractAddress = contract_address_const::<2>();

        let amount: u256 = u256 { low: 1000_u128, high: 0_u128 };

        set_contract_address(account);
        erc20.transfer(recipient, amount);
        assert(erc20.balance_of(account) == initial_supply - amount, 'Balance should be reduced');
        assert(erc20.balance_of(recipient) == amount, 'Balance be equal to amount');
    }

    fn get_timestamp() -> u64 {
        get_block_info().unbox().block_timestamp
    }
}
