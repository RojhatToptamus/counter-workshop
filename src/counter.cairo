#[starknet::interface]
pub trait ICounter<TContractState> {
    fn get_counter(self: @TContractState) -> u32;
    fn increase_counter(ref self: TContractState);
}
#[starknet::contract]
pub mod counter_contract {
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        CounterIncreased: CounterIncreased,
    }
    #[derive(Drop, starknet::Event)]
    pub struct CounterIncreased {
        #[key]
        pub value: u32,
    }

    #[storage]
    struct Storage {
        counter: u32
    }
    #[constructor]
    fn constructor(ref self: ContractState, initial_value: u32) {
        self.counter.write(initial_value);
    }
    // Public Functions
    #[abi(embed_v0)]
    impl Counter of super::ICounter<ContractState> {
        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read()
        }
        fn increase_counter(ref self: ContractState) {
            self.counter.write(self.counter.read() + 1);
            self.emit(Event::CounterIncreased(CounterIncreased { value: self.counter.read() }));
        }
    }
}
