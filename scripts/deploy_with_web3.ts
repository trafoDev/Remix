import { deploy } from './web3-lib'



await (async () => {
    try {
        const result = await deploy('MembershipRights', [])
        console.log(`address: ${result.address}`)
    } catch (e) {
        console.log(e.message)
    }
})()