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

#[starknet::interface]
trait ITokenRemover<TContractState> {
    fn set_destination(ref self: TContractState, destination: ContractAddress) -> ();

    fn get_destination(self: @TContractState, source: ContractAddress) -> ContractAddress;
    fn move_all(self: @TContractState, array_to_move: Array<Movable>) -> ();
}

#[starknet::contract]
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

    #[storage]
    struct Storage {
        destinations: LegacyMap::<ContractAddress, ContractAddress>, 
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        DestinationSet: DestinationSet, 
    }
    #[derive(Drop, starknet::Event)]
    struct DestinationSet {
        source: ContractAddress,
        dest: ContractAddress,
    }


    #[constructor]
    fn constructor(ref self: ContractState, ) {}

    #[external(v0)]
    impl TokenRemover of super::ITokenRemover<ContractState> {
        fn get_destination(self: @ContractState, source: ContractAddress) -> ContractAddress {
            let caller = get_caller_address();
            let caller_felt: felt252 = caller.into();

            let dest = self.destinations.read(source);
            let dest_felt: felt252 = dest.into();
            dest
        }

        fn set_destination(ref self: ContractState, destination: ContractAddress) {
            let caller = get_caller_address();
            self.destinations.write(caller, destination);
            let dest_felt: felt252 = destination.into();
            self.emit(Event::DestinationSet(DestinationSet { source: caller, dest: destination }));
        }

        fn move_all(self: @ContractState, array_to_move: Array<Movable>) {
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
                    .transfer_from(
                        caller, self.destinations.read(caller), *array_to_move.at(index).amount
                    );
                index += 1;
            }
        }
    }
}
