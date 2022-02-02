// @ts-nocheck
import { ethers } from "ethers";
import { caplABI, rewardsABI, vaultABI, balancerVault as a balancerVaultABI } from "../../contracts/abi";
import { capl, vault, rewards, vaultContract as balancerVault, caplUSDCPoolId } from "../../contracts";
import { markRaw } from "vue";

const ChainID = process.env.VUE_APP_NETWORK_ID
  ? Number(process.env.VUE_APP_NETWORK_ID)
  : 1;

const state = {
  rewardsContract: null,
  vaultContract: null,
  caplContract: null,
  caplBalance: 0,
  balancerVaultContract: null,
  balancerVault: {}
};

const getters = {
  getCAPLContract(state) {
    return state.caplContract;
  },
  getCAPLBalance(state) {
    return state.caplBalance;
  },

  // get CAPLUSDPollContract
  getBalancerVaultContract(state) {
    return state.balancerVaultContract;
  },

  // get balancerVault
  getBalancerVault() {
    return state.balancerVault;
  }
};

const actions = {
  async setContracts({ commit, rootState }) {
    const provider = rootState.accounts.web3Provider;
    commit(
      "setCAPLContract",
      markRaw(new ethers.Contract(capl[ChainID], caplABI, provider))
    );
    commit(
      "setVaultContract",
      markRaw(new ethers.Contract(vault[ChainID], vaultABI, provider))
    );
    commit(
      "setRewardsContract",
      markRaw(new ethers.Contract(rewards[ChainID], rewardsABI, provider))
    );

    // set vault contract
    commit(
      "setBalancerVaultContract",
      markRaw(new ethers.Contract(balancerVault[ChainID], balancerVaultABI, provider))
    );
  },

  async getCAPLBalance({ commit, rootState }) {
    // get address from rootstate,
    const address = rootState.accounts.activeAccount;
    // get contract from contract state (local state)
    if (state.caplContract === null) {
      actions.setContracts({ commit, rootState });
    }

    const caplContract = state.caplContract;
    // get balance
    const caplBalance = await caplContract.balanceOf(address);
    // parse balance, set new value in the local state
    commit("setCAPLBalance", ethers.utils.formatUnits(caplBalance, 18));
  },

  async getBalancerVault({ commit, rootState }) {
    // get poolID
    const poolID = caplUSDCPoolId[ChainID];

    // if state.balancerVaultContract is null, call the `setContracts` function
    if (state.balancerVaultContract === null) {
      actions.setContracts({ commit, rootState });
    }
    const balancerVaultContract = state.balancerVaultContract;
    
    // call getPoolTokens
    const balancerVault = await balancerVaultContract.getPoolTokens(poolID);
    
    // parse balance
    const balances = balancerVault.balances.map(obj => ethers.utils.formatUnits(obj, 18));
    
    // call setPoolTokens in mutations.
    commit("setBalancerVault", {
      "tokens" : balancerVault.tokens,
      "balances":  balances
    });
  },
};

const mutations = {
  setCAPLContract(state, _contract) {
    state.caplContract = _contract;
  },
  setVaultContract(state, _contract) {
    state.vaultContract = _contract;
  },
  setRewardsContract(state, _contract) {
    state.rewardsContract = _contract;
  },
  setCAPLBalance(state, _balance) {
    state.caplBalance = _balance;
  },

  // assign vault contract
  setBalancerVaultContract(state, _contract) {
    state.balancerVaultContract = _contract;
  },

  // assign poolTokens.
  setBalancerVault(state, _balancerVault) {
    state.balancerVault = _balancerVault;
  }
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
