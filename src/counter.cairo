#[starknet::interface]
pub trait ICounter<TContractState> {
    fn get_counter(self: @TContractState) -> u32;
    fn increase_counter(ref self: TContractState);
}
#[starknet::contract]
pub mod counter_contract {
    use core::starknet::{ContractAddress};
    use kill_switch::{IKillSwitchDispatcher, IKillSwitchDispatcherTrait};
    use openzeppelin::access::ownable::OwnableComponent;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        CounterIncreased: CounterIncreased,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }
    #[derive(Drop, starknet::Event)]
    pub struct CounterIncreased {
        #[key]
        pub value: u32,
    }

    #[storage]
    struct Storage {
        counter: u32,
        kill_switch: ContractAddress,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }
    #[constructor]
    fn constructor(
        ref self: ContractState,
        initial_value: u32,
        kill_switch: ContractAddress,
        initial_owner: ContractAddress
    ) {
        self.ownable.initializer(initial_owner);
        self.counter.write(initial_value);
        self.kill_switch.write(kill_switch);
    }
    // Public Functions
    #[abi(embed_v0)]
    impl Counter of super::ICounter<ContractState> {
        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read()
        }
        fn increase_counter(ref self: ContractState) {
            // Check if the caller is the owner
            self.ownable.assert_only_owner();
            let kill_switch_dispatcher = IKillSwitchDispatcher {
                contract_address: self.kill_switch.read()
            };
            // Check if the kill switch is activated
            let is_kill_switch_active = kill_switch_dispatcher.is_active();
            assert!(is_kill_switch_active == false, "Kill Switch is active");

            self.counter.write(self.counter.read() + 1);
            self.emit(Event::CounterIncreased(CounterIncreased { value: self.counter.read() }));
        }
    }
}
