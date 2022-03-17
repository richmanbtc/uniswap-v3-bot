uniswap v3 lp調整ボット

## 実装メモ

chainlink keeperを使うと全自動化できる(未実装)。

これ使ってみた
https://twitter.com/eth_call/status/1502361233940430852

LPの出し方はこれが参考になった。
https://kyoronut.github.io/

直近24時間のボラティリティーと直近価格でLP出してみる。
全自動化する場合は、現在のレンジを超えるか、一定時間経ったら出しなおすとかで良さそう。

charm financeのコントラクトが参考になった
https://charm.fi/
https://etherscan.io/address/0x1cEA471aab8c57118d187315f3d6Ae1834cCD836

rebalance

1. remove
2. collect
3. add

https://etherscan.io/tx/0xdb794d07fdba54243d6007d74fe2ad5135fd40249d7da19159009e8aba1d6ba4

NonfungiblePositionManagerのイベントが出ていないから、
多分プールを直接操作している。
https://github.com/Uniswap/v3-periphery/blob/main/contracts/NonfungiblePositionManager.sol

mint量の計算
https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/LiquidityManagement.sol#L51
https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/LiquidityAmounts.sol

トークン比率の偏りを戻す
https://vividot-de.fi/entry/Uniswap-V3-Vault
これのrebalancing orderで行う

charm financeのコントラクト
https://github.com/charmfinance/alpha-vaults-contracts/tree/main/contracts
