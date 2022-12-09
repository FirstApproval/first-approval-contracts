from brownie import *


def test_set_settings(first_approval, owner, alice):
    treasury = alice
    feeNumerator = 10
    burnNumerator = 10

    tx = first_approval.setSettings(
        treasury,
        feeNumerator,
        burnNumerator,
        {"from": owner}
    )

    assert tx.events['SettingsSet']['treasury'] == treasury
    assert tx.events['SettingsSet']['feeNumerator'] == feeNumerator
    assert tx.events['SettingsSet']['burnNumerator'] == burnNumerator
    assert first_approval.settings() == (treasury, feeNumerator, burnNumerator)


def test_transfer_no_fees(first_approval, owner, alice, bob):
    amount_before = first_approval.balanceOf(alice)
    amount = 1e18
    first_approval.transfer(bob, amount, {"from": alice})
    assert first_approval.balanceOf(alice) - amount_before == -amount


def test_transfer_with_fee(first_approval, owner, alice, bob):
    treasury = owner
    feeNumerator = 100  # 1%
    burnNumerator = 0

    tx = first_approval.setSettings(
        treasury,
        feeNumerator,
        burnNumerator,
        {"from": owner}
    )

    amount_before = first_approval.balanceOf(alice)
    amount = 1e18
    tx = first_approval.transfer(bob, amount, {"from": alice})
    assert tx.events['FeeCollected']['from'] == alice
    assert tx.events['FeeCollected']['to'] == owner
    assert tx.events['FeeCollected']['amount'] == 1e18 / 100
    assert first_approval.balanceOf(alice) - amount_before == -1e18 * 101 / 100
    assert first_approval.balanceOf(owner) == 1e18 / 100


def test_transfer_with_burn(first_approval, owner, alice, bob):
    treasury = alice
    feeNumerator = 0
    burnNumerator = 100  # 1%

    tx = first_approval.setSettings(
        treasury,
        feeNumerator,
        burnNumerator,
        {"from": owner}
    )

    amount_before = first_approval.balanceOf(alice)
    total_supply_before = first_approval.totalSupply()
    amount = 1e18
    first_approval.transfer(bob, amount, {"from": alice})
    assert first_approval.balanceOf(alice) - amount_before == -1e18 * 101 / 100
    assert first_approval.totalSupply() - total_supply_before == -1e18 / 100
