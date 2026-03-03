use crate::{Transfer, test::utils};

#[test]
unconstrained fn mint_success() {
    let (env, contract_address, owner, user) = utils::setup_contract(false);

    env.call_private(owner, Transfer::at(contract_address).mint(user, 100u128));

    let balance = env.utility(Transfer::at(contract_address).get_balance(user));
    assert(balance == 100u128);
}