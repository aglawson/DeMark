import { useState } from 'react'
import './App.css'
import {ethers} from 'ethers'
import {abi} from './assets/abi'
import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

let provider, signer, contract = null;
const contractAddress = '0x8f9f0744Ed2f0fb1587D2ddFed6d7A7f876cBc9C'
const explorerAddress = 'https://sepolia-blockscout.scroll.io/address/'

function App() {
  const [userAddress, setUserAddress] = useState(null)
  const [jobs, setJobs] = useState([])
  const [proposeForm, setProposeForm] = useState(false)
  const [submissions, setSubmissions] = useState([])

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

      const props = await getProposals()
      for(let i = 0; i < props.length; i++) {
        let subs = await getSubmissions(i)
        console.log(subs)
      }
      toast.success("Connected!")
    }
  }

  async function getProposals() {
    const proposals = await contract.getIncompleteJobs()
    console.log(proposals)
    setJobs(proposals)
    return proposals
  }

  async function getSubmissions(jobId) {
    const submissionsData = await contract.getSubmissionsForJob(0)
    let temp = {
      jobId: jobId,
      subs: []
    }
    for(let i = 0; i < submissionsData.length; i++) {
      console.log(submissionsData[i])
      temp.subs.push(submissionsData[i])
    }
    let arrayTemp = submissions
    arrayTemp.push(temp)
    setSubmissions(arrayTemp)
    console.log(arrayTemp)
    
    return submissions
  }

  async function createProposal(e) {
    e.preventDefault()
    try {
      const tx = await contract.proposeJob(document.getElementById('jobDescription').value, {value: '1000000000000000'})
      await tx.wait(1)
      toast.success("Proposal created successfully!")
    } catch(error) {
      console.log(error.reason)
      toast.error(`Error: ${error}`)
    }
  }

  async function acceptSubmission(jobId, submissionId) {
    try {
      const tx = await contract.markComplete(jobId, submissionId)
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

      <button style={{display: proposeForm ? 'none' : ''}} onClick={() => setProposeForm(true)}>Propose Job</button>
      <form style={{display: proposeForm ? '' : 'none'}} onSubmit={(e) => createProposal(e, document.getElementById('jobDescription').value)}>
        <input id='jobDescription' placeholder='Brief Job Description'></input>
        <button type='submit'>Submit Job</button>
        <button onClick={(e) => {e.preventDefault(); setProposeForm(false)}}>Cancel</button>
      </form>

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
              <input id='contractAddress' placeholder='Contract Address' style={{display: job[0] == userAddress ? 'none' : ''}}></input>
              <button onClick={() => submitSolution(index)} style={{display: job[0] == userAddress ? 'none' : ''}}>Submit Your Solution</button>
              <input style={{display: userAddress == job[0] ? '' : 'none'}} type='text' placeholder='Submission ID' id='subId'></input>
              <button style={{display: userAddress == job[0] ? '' : 'none'}}  onClick={() => acceptSubmission(index, document.getElementById('subId').value)}>Accept Submission</button>
              </div>
          ))}
        </div>
      </div>
    </div>
  )
}

export default App

