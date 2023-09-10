import { useState } from 'react'
import './App.css'
import {ethers} from 'ethers'
import {abi} from './assets/abi'
import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

let provider, signer, contract = null;
const contractAddress = '0xe317aBa6C197fa14d199ff4F2De4b1c33EF6965A'

function App() {
  const [userAddress, setUserAddress] = useState(null)
  const [jobs, setJobs] = useState([])

  async function init() {
    if (window.ethereum == null) {
      console.log("MetaMask not installed");
    } else {
      provider = new ethers.BrowserProvider(window.ethereum);
      const nw = await provider.getNetwork();
      // Check if the network is correct, if not, change it
      if (Number(nw.chainId) !== 534351) {
        try {
          await window.ethereum.request({
            method: 'wallet_switchEthereumChain',
            params: [{ chainId: '0x8274f' }],
          })
          // window.location.reload();
          provider = new ethers.BrowserProvider(window.ethereum);

        } catch (switchError) {
          console.log({ switchError })
          if (switchError.code === 4902) {
            try {
              await window.ethereum.request({
                method: 'wallet_addEthereumChain',
                params: [{ 
                  chainId: '0x8274f',
                  chainName: 'Scroll Sepolia Testnet',
                  nativeCurrency: {
                    name: 'ETH',
                    symbol: 'ETH',
                    decimals: 18
                  },
                  rpcUrls: ['https://scroll-sepolia.blockpi.network/v1/rpc/public'],
                  blockExplorerUrls: ['https://sepolia-blockscout.scroll.io']
                }],
              });
              window.location.reload();
                    provider = new ethers.BrowserProvider(window.ethereum);

            } catch (addError) {
              console.error(addError);
            }
          }
        }
      }


      signer = await provider.getSigner();
      contract = new ethers.Contract(contractAddress, abi, signer);
      setUserAddress(await signer.getAddress());

      await getProposals()
      toast.success("Connected!")
    }
  }

  async function getProposals() {
    const proposals = await contract.getIncompleteJobs()
    console.log(proposals)
    setJobs(proposals)
  }

  async function getSubmissions(jobId) {

  }

  async function createProposal(jobDescription) {
    try {
      const tx = await contract.createProposal(jobDescription)
      await tx.wait(1)
      toast.success("Proposal created successfully!")
    } catch(error) {
      console.log(error.reason)
      toast.error(`Error: ${error}`)
    }
  }

  async function acceptSubmission(completedBy) {
    try {
      const tx = await contract.markComplete(completedBy)
      await tx.wait(1)
      toast.success("Transaction complete!")
    } catch (error) {
      console.log(error.reason)
      toast.error(`Error: ${error}`)
    }
  }  

  async function submitSolution(key) {
    try {
      const tx = await contract.submitSolution(key, document.getElementById('contractAddress').value)
      console.log(tx)
      await tx.wait(1)
      toast.success("Contract submitted!")
    } catch(error) {
      toast.error(`Error: ${error}`)
    }
  }

  return (
    <div className='w-full'>
      <ToastContainer
        position="bottom-right"
        autoClose={5000}
        hideProgressBar={false}
        newestOnTop={false}
        closeOnClick
        rtl={false}
        pauseOnFocusLoss
        draggable
        pauseOnHover
      />

      {userAddress ? (
        <button style={{position: 'fixed', top: '1%', right: '1%'}}> 
         {userAddress.substring(0,6) + '...' + userAddress.substring(userAddress.length - 4, userAddress.length)}
        </button>
      ): (
        <div>
        <button onClick={() => init()}>
          {'Connect Wallet'}
        </button>
      </div>
      )}

      <div style={{display: jobs.length > 0 ? '' : 'none'}} className='w-full'>
        <h1>Open Jobs</h1>
        <div className='jobs'>
          {jobs.map((job, index) => (
            <div className='job' key={index}>
              <div className='job-info'>
              <span className='client'>{job[0]}</span>
                <h2>{job[2]}</h2>
                <span>This job consists of making a {job[2]}. You have until September 29th to submit.</span>
                <span className='price'>{Number(job[1]) < 100000000000000 ? `<${ethers.formatEther(100000000000000)}` : `${(Number(ethers.formatEther(job[1]))).toFixed(4)}`}Ξ</span>
              </div>
              <input id='contractAddress'></input>
              <button onClick={() => submitSolution(index)}>Apply For Job</button>
              <div className='divider'/>
              </div>
          ))}
        </div>
      </div>
    </div>
  )
}

export default App

