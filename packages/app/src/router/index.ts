import { createRouter, createWebHistory } from "vue-router";
import HomePage from "../pages/Home.vue";
import Dashboard from "../pages/Dashboard.vue";
import RewardsPage from "../pages/Rewards.vue";
import StakePage from "../pages/Stake.vue";
import SwapPage from "../pages/Swap.vue";
import TreasuryPage from "../pages/Treasury.vue";
import PlatformPage from "../pages/Platform.vue";
import PortfolioPage from "../pages/Portfolio.vue";
import LiquidityPage from "../pages/Liquidity.vue";
import NFT from "../pages/NFT.vue";
import TreasuryFundPage from "../pages/TreasuryFund.vue"; 
import Wallet from "../pages/Wallet.vue"; 


const routeInfos = [
  {
    path: "/",
    component: HomePage,
  },
  {
    path: "/dashboard",
    component: Dashboard,
  },
  {
    path: "/stake",
    component: StakePage,
  },
  {
    path: "/reward",
    component: RewardsPage,
  },
  {
    path: "/swap",
    component: SwapPage,
  },
  {
    path: "/liquidity",
    component: LiquidityPage,
  },
  {
    path: "/treasury",
    component: TreasuryPage,
  },
  {
    path: "/platform",
    component: PlatformPage,
  },
  {
    path: "/portfolio",
    component: PortfolioPage,
  },
  {
    path: "/nft",
    component: NFT,
  },
  {
    path: "/treasuryfund",
    component: TreasuryFundPage,
  },
  {
    path: "/wallet",
    component: Wallet,
  }
];

const router = createRouter({
  history: createWebHistory(),
  routes: routeInfos,
});

export default router;
