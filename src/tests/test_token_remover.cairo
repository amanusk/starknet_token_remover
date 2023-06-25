#[cfg(test)]
mod token_remover_test {
    use token_remover::token_remover::remover::TokenRemover;
    use token_remover::token_remover::remover::ITokenRemoverDispatcher;
    use token_remover::token_remover::remover::ITokenRemoverDispatcherTrait;
    use token_remover::token_remover::remover::Movable;

    use token_remover::tests::mock_erc20::MockERC20;
    use token_remover::erc20::erc20::IERC20Dispatcher;
    use token_remover::erc20::erc20::IERC20DispatcherTrait;

    use starknet::testing::set_caller_address;
    use starknet::testing::set_contract_address;
    use starknet::testing::set_block_timestamp;

    use starknet::contract_address_const;
    use starknet::get_block_info;
    use starknet::ContractAddress;
    use starknet::Felt252TryIntoContractAddress;
    use starknet::TryInto;
    use starknet::Into;
    use starknet::OptionTrait;
    use starknet::class_hash::Felt252TryIntoClassHash;

    use starknet::syscalls::deploy_syscall;
    use array::ArrayTrait;
    use result::ResultTrait;
    use serde::Serde;

    use debug::PrintTrait;


    const NAME: felt252 = 111;
    const SYMBOL: felt252 = 222;
    fn setup() -> (ContractAddress, IERC20Dispatcher, ITokenRemoverDispatcher) {
        let account: ContractAddress = contract_address_const::<0xDEADBEAF>();
        set_caller_address(account);

        let initial_supply: u256 = u256 { low: 1000000000_u128, high: 0_u128 };

        // Deploy ERC20
        let mut calldata = ArrayTrait::new();
        NAME.serialize(ref calldata);
        SYMBOL.serialize(ref calldata);
        18.serialize(ref calldata);
        initial_supply.serialize(ref calldata);
        account.serialize(ref calldata);

        let (erc20_address, _) = deploy_syscall(
            MockERC20::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
        )
            .unwrap();

        // deploy remover
        let mut calldata = ArrayTrait::new();
        let (remover_address, _) = deploy_syscall(
            TokenRemover::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
        )
            .unwrap();
        let erc20 = IERC20Dispatcher { contract_address: erc20_address };
        let token_remover = ITokenRemoverDispatcher { contract_address: remover_address };

        (account, erc20, token_remover)
    }

    #[test]
    #[available_gas(10000000)]
    fn test_constructor() {
        let (_, _, _) = setup();
    }
    #[test]
    #[available_gas(1000000)]
    fn test_set_destination() {
        let (account, erc20, token_remover) = setup();
        let amount: u256 = 1.into();
        let account: ContractAddress = contract_address_const::<0xDEADBEAF>();
        let dest: ContractAddress = contract_address_const::<0xDECD>();

        // let (account, erc20, token_remover) = setup();
        set_contract_address(account);

        token_remover.set_destination(dest);
        let stored_dest = token_remover.get_destination(account);
        assert(stored_dest == dest, 'Dest not stored');
    }

    #[test]
    #[available_gas(10000000)]
    fn test_remove_tokens() {
        let (account, erc20, token_remover) = setup();
        let amount: u256 = 1.into();

        let dest: ContractAddress = contract_address_const::<0xDECD>();

        // start prank account
        set_contract_address(account);
        erc20.approve(token_remover.contract_address, amount);

        assert(
            erc20.allowance(account, token_remover.contract_address) == amount, 'Allowance not set'
        );

        // set destination
        token_remover.set_destination(dest);

        let movable = Movable { token_address: erc20.contract_address, amount: amount };

        let mut movables_array = ArrayTrait::<Movable>::new();
        movables_array.append(movable);

        // move all tokens
        token_remover.move_all(movables_array);
        assert(
            erc20.allowance(account, token_remover.contract_address) == 0, 'Allowance not changed'
        );

        let dest_balance = erc20.balance_of(dest);
        assert(dest_balance == amount, 'Did not move');
    }
}
