from brownie import *
import pytest


@pytest.fixture
def owner(accounts):
    return accounts[0]


@pytest.fixture
def alice(accounts):
    return accounts[1]


@pytest.fixture
def bob(accounts):
    return accounts[2]


@pytest.fixture
def first_approval(owner, alice, bob):
    token = FirstApproval.deploy({"from": owner})
    amount = 1000 * 1e18
    token.mint(alice, amount, {"from": owner})
    token.mint(bob, amount, {"from": owner})
    yield token
