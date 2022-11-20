import { Button, Row, Col, Card, DatePicker, Divider, Input, Progress, Slider, Spin, Switch } from "antd";
import React, { useState } from "react";
import petImage from '../cute-pet.png';
import { utils } from "ethers";
import { SyncOutlined } from "@ant-design/icons";

import { Address, Balance, Events } from "../components";

export default function ExampleUI({
  countPetStrokes,
  address,
  mainnetProvider,
  localProvider,
  yourLocalBalance,
  price,
  tx,
  readContracts,
  writeContracts,
}) {
  return (
    <div style={{ fontFamily: 'Comic Sans MS', fontSize: '200%' }}>
      <div style={{ margin: 8 }}>
        <Button
          style={{
            margin: 20,
            paddingBottom: '10px',
            fontSize: '120%',
            width: '850px',
            height: '80px',
            borderRadius: '30px',
            borderWidth: '8px',
            borderColor: '#2266FF',
            background: '#00FF00',
            color: '#FF0000'
          }}
          onClick={async () => {
            /* look how you call strokeThePet on your contract: */
            /* notice how you pass a call back for tx updates too */
            const result = tx(writeContracts.DemoPetStroker.strokeThePet(), update => {
              console.log("📡 Transaction Update:", update);
              if (update && (update.status === "confirmed" || update.status === 1)) {
                console.log(" 🍾 Transaction " + update.hash + " finished!");
                console.log(
                  " ⛽️ " +
                    update.gasUsed +
                    "/" +
                    (update.gasLimit || update.gas) +
                    " @ " +
                    parseFloat(update.gasPrice) / 1000000000 +
                    " gwei",
                );
              }
            });
            console.log("awaiting metamask/web3 confirm result...", result);
            console.log(await result);
          }}
        >
          PRESS me to stroke pet with PAINful MM popup
        </Button>
      </div>
      <img src={petImage} alt="Cute Pet" style={{ margin: '10px' }} />
      <p style={{ color: 'darkgreen' }}>pet as been STROKed like {countPetStrokes} times</p>
      <p style={{ color: 'grey' }}>cure pain to use METAMASK SNAP for no popup... coming s👀N</p>
      <div style={{ color: '#BB8800', fontSize: '50%' }}>
        <div style={{ }}>
          <p>&nbsp;</p>
          <p><b>Instructions</b></p>
          <p>Log in to Metamask, change network to Goerli testnet</p>
          <p>If you need Goerli ETH, use the faucet <a href="https://goerlifaucet.com/" target="_blank"><u>here</u></a></p>
          <p>Bridge Goerli ETH to Optimistic Goerli <a href="https://app.optimism.io/bridge/deposit" target="_blank"><u>here</u></a></p>
          <p>Add the Optimistic Goerli network to Metamask using <a href="https://chainlist.org/chain/420" target="_blank"><u>Chainlist</u></a></p>
          <p>Inspect the `stroke pet` contract and <a href="https://github.com/davidryan59/scaffold-eth/tree/stroke-pet" target="_blank"><u>GitHub repo</u></a></p>
          <p>&nbsp;</p>
        </div>
        <p style={{ fontSize: '50%' }}>
          <a href="https://chainlist.org/chain/420" target="_blank"><u>Add Optimistic Goerli network</u></a>
        </p>
        <p style={{ fontSize: '50%' }}>
          <a href="https://app.optimism.io/bridge/deposit" target="_blank"><u>Deposit Goerli ETH to Optimistic Goerli</u></a>
        </p>
        <p style={{ fontSize: '50%' }}>
          Goerli <a href="https://goerli.etherscan.io/address/0xf06eb42a778be7a24a4ea4ef48ea880d669fc949#code" target="_blank"><u>Contract</u></a> and <a href="https://goerlifaucet.com/" target="_blank"><u>Faucet</u></a>
        </p>
        <p style={{ fontSize: '50%' }}>
          <a href="https://github.com/davidryan59/scaffold-eth/tree/stroke-pet" target="_blank"><u>GitHub repo</u></a>
        </p>
      </div>
      <div style={{ margin: '500px', color: 'rgba(255,0,0,0.6)', fontSize: '45%' }}>graphic design proudly presented by drcoder.eth</div>
    </div>
  );
}
