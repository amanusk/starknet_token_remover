use starknet::get_caller_address;
use starknet::contract_address_const;
use starknet::ContractAddress;
use starknet::Into;

use zeroable::Zeroable;
use array::ArrayTrait;
use array::SpanTrait;
use debug::PrintTrait;

use token_remover::erc20::erc20::IERC20;
use token_remover::erc20::erc20::IERC20Dispatcher;
use token_remover::erc20::erc20::IERC20DispatcherTrait;

#[derive(Drop, Serde, Copy)]
struct Movable {
    token_address: ContractAddress,
    amount: u256,
}

#[abi]
trait ITokenRemover {
    fn set_destination(destination: ContractAddress) -> ();
    fn get_destination(source: ContractAddress) -> ContractAddress;
    fn move_all(array_to_move: Array<Movable>) -> ();
}

#[contract]
mod TokenRemover {
    use starknet::get_caller_address;
    use starknet::contract_address_const;
    use starknet::ContractAddress;
    use starknet::Into;

    use zeroable::Zeroable;
    use array::ArrayTrait;
    use array::SpanTrait;

    use token_remover::erc20::erc20::IERC20;
    use debug::PrintTrait;

    use super::Movable;

    use token_remover::erc20::erc20::IERC20Dispatcher;
    use token_remover::erc20::erc20::IERC20DispatcherTrait;

    struct Storage {
        destinations: LegacyMap::<ContractAddress, ContractAddress>, 
    }


    #[event]
    fn DestinationSet(source: ContractAddress, dest: ContractAddress) {}


    #[constructor]
    fn constructor() {}

    #[view]
    fn get_destination(source: ContractAddress) -> ContractAddress {
        let caller = get_caller_address();
        let caller_felt: felt252 = caller.into();

        let dest = destinations::read(source);
        let dest_felt: felt252 = dest.into();
        dest
    }

    #[external]
    fn set_destination(destination: ContractAddress) {
        let caller = get_caller_address();
        destinations::write(caller, destination);
        let dest_felt: felt252 = destination.into();
        DestinationSet(caller, destination);
    }

    #[external]
    fn move_all(array_to_move: Array<Movable>) {
        let caller = get_caller_address();
        let mut index = 0;
        loop {
            if index == array_to_move.len() {
                break ();
            }
            let erc20 = IERC20Dispatcher {
                contract_address: *array_to_move.at(index).token_address
            };
            // TODO: handle transferFrom
            // TODO: handle no destination set
            // TODO: handle no allowance
            // TODO: handle no balance
            // TODO: gracefully fail on error
            erc20
                .transfer_from(caller, destinations::read(caller), *array_to_move.at(index).amount);
            index += 1;
        }
    }
}
