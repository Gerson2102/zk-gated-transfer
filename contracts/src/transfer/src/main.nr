use aztec::macros::aztec;

#[aztec]
pub contract Transfer {
    // aztec library imports
    use aztec::{
        macros::{functions::{external, initializer, only_self, view}, storage::storage},
        protocol::address::AztecAddress,
        messages::message_delivery::MessageDelivery,
        state_vars::{PublicImmutable, PublicMutable, Map, Owned},
    };

    use balance_set::BalanceSet;

    // @param owner The address of the owner
    #[storage]
    struct Storage<Context> {
        owner: PublicImmutable<AztecAddress, Context>,
        whitelist: Map<AztecAddress, PublicMutable<bool, Context>, Context>,
        balances: Owned<BalanceSet<Context>, Context>,
    }

    /// @dev Initialize the contract
    /// @param owner The address of the owner
    #[external("public")]
    #[initializer]
    fn constructor(owner: AztecAddress) {
        self.storage.owner.initialize(owner);
    }

    /// @dev Adds a user to the whitelist
    /// @param user The address of the user to add to the whitelist
    #[external("public")]
    fn add_to_whitelist(user: AztecAddress) {
        self.call_self._only_owner();
        self.storage.whitelist.at(user).write(true);
    }

    /// @dev Removes a user from the whitelist
    /// @param user The address of the user to remove from the whitelist
    #[external("public")]
    fn remove_from_whitelist(user: AztecAddress) {
        self.call_self._only_owner();
        self.storage.whitelist.at(user).write(false);
    }

    /// @dev Retrieves the address of the user
    /// @return The address of the user
    #[external("public")]
    #[view]
    fn get_owner() -> AztecAddress {
        self.storage.owner.read()
    }

    #[external("private")]
    fn transfer(to: AztecAddress, amount: u128) {
        self.enqueue_self._only_whitelisted(self.msg_sender());
        self.enqueue_self._only_whitelisted(to);
        
        let sender = self.msg_sender();
        
        self.storage.balances.at(sender).sub(amount).deliver(MessageDelivery.ONCHAIN_CONSTRAINED);
        self.storage.balances.at(to).add(amount).deliver(MessageDelivery.ONCHAIN_CONSTRAINED);
    }

    #[external("private")]
    fn mint(recipient: AztecAddress, amount: u128) {
        self.enqueue_self._only_owner();
        self.storage.balances.at(recipient).add(amount).deliver(MessageDelivery.ONCHAIN_CONSTRAINED);
    }

    #[external("public")]
    #[only_self]
    fn _only_whitelisted(address: AztecAddress) {
        assert(self.storage.whitelist.at(address).read(), "User not in whitelist");
    }

    #[external("public")]
    #[only_self]
    fn _only_owner() {
        assert(self.msg_sender() == self.storage.owner.read(), "Not owner");
    }

    #[external("utility")]
    unconstrained fn get_balance(address: AztecAddress) -> u128 {
        self.storage.balances.at(address).balance_of()
    }
}
