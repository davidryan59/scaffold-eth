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
            width: '700px',
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
          PREss Me to stroKe the peT pAinFuLly
        </Button>
      </div>
      <img src={petImage} alt="Cute Pet" style={{ margin: '10px' }} />
      <p style={{ color: 'darkgreen' }}>pEt as beEN stROked likE {countPetStrokes} tiMEs</p>
      <p style={{ fontSize: '50%' }}>
        <a href="https://goerli.etherscan.io/address/0xf06eb42a778be7a24a4ea4ef48ea880d669fc949#code" target="_blank"><u>Goerli Contract</u></a> | <a href="https://github.com/davidryan59/scaffold-eth/tree/stroke-pet" target="_blank"><u>GitHub repo</u></a>
      </p>
      <div style={{ margin: '500px', color: 'rgba(255,0,0,0.6)', fontSize: '45%' }}>graphic design proudly presented by drcoder.eth</div>
    </div>
  );
}
