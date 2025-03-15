<script>
  import { onDestroy, onMount } from "svelte";
  import Web3 from "web3";
  import contractABI from "./abi.json"

  const contractAddress = "0xF3f548C34013539dc58EFa19Cb0037E3aad9DB76";
  let accountConnected = false;

  let account = "";
  let contract;

  let web3;
  let waitingText;
  let status;

  let buttons = [{text: "DAI"}, {text: "LINK"}, {text: "USDC"}, {text: "WBTC"}, {text: "WETH"}];

  async function connectWallet() {
    if (accountConnected == false) {
      if (window.ethereum) {
        try {

          await window.ethereum.request({ method: "eth_requestAccounts" });

          const accounts = await web3.eth.getAccounts();
          account = accounts[0];
          accountConnected = true;

        } catch (error) {
          console.error("User denied account access", error);
        }
      } else {
        console.error("Non-Ethereum browser detected. Please install MetaMask!");
      }
    } else {
      account = "";
      accountConnected = false;
    }
  }

  function handleAccountsChanged(accounts) {
    if (accounts.length === 0) {
      account = "";
      accountConnected = false;
    } else {
      account = accounts[0];
      accountConnected = true;
    }
  }

  onMount(() => {
    web3 = new Web3(window.ethereum);
    contract = new web3.eth.Contract(contractABI, contractAddress);
    console.log(contract);
    
    if (window.ethereum) {
      window.ethereum.on("accountsChanged", handleAccountsChanged);
    }
  });

  onDestroy(() => {
    if (window.ethereum && handleAccountsChanged) {
      window.ethereum.removeListener("accountsChanged", handleAccountsChanged);
    }
  });

  async function getHighestYield(tokenName) {
    try {
      if (!contract) {
        waitingText = "Contract not initialized";
        return;
      }

      if(account == "") {
        waitingText = "Connect Wallet First!"
      }

      waitingText = "Loading..."

      const txResult = await contract.methods.getEstimatedAPY(tokenName).send({
        from: account
      });

      const result = await contract.methods.getEstimatedAPY(tokenName).call();

      status = {
        selectedBestYield: result[0],
        yield: Number(result[1]) / 100,
        fundsTransferred: result[2]
      };

      if(status.selectedBestYield) {
        waitingText = `Congratulations! You're right, ${tokenName} has an APY of ${status.yield}%. Check your wallet for rewards 🥳!`;
      } else {
        waitingText = `Incorrect! ${tokenName} has an APY of ${status.yield}%`;
      }

    } catch (error) {
      console.log("Error calling getEstimatedAPY:", error);
      waitingText = `Error: ${error.message}`;
    }
  }
</script>

<main>
  <div class="wallet-button">
    <button on:click={connectWallet}>{account ? `Connected: ${account}` : "Connect Wallet"}</button>
  </div>

  <div class="middle-container">
    <h2>Select the token reserve on AAVE sepolia testnet that is currently offering the highest yield.</h2>
    <div class="buttons-container">
      {#each buttons as btn, index}
        <button class="action-button" on:click={() => getHighestYield(btn.text)}>{btn.text}</button>
      {/each}
    </div>
    <p>{waitingText}</p>
  </div>
</main>

<style>
  .wallet-button {
    position: fixed;
    top: 10px; 
    left: 50%;
    transform: translateX(-50%);
    padding: 10px 20px;
    font-size: 16px;
    border: none;
    border-radius: 5px;
    cursor: pointer;
    z-index: 1000; 
  }

  .middle-container {
    display: flex;
    flex-direction: column;
    align-items: center;
    margin-top: 80px; 
  }

  .buttons-container {
    display: flex;
    justify-content: center;
    gap: 20px;
    margin-top: 20px;
  }

  .action-button {
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 10px;
    border-radius: 5px;
    cursor: pointer;
  }

</style>
