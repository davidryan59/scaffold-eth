import { PageHeader } from "antd";
import React from "react";

// displays a page header

export default function Header({networkName}) {
  return (
    <a href="/">
      <PageHeader
        title={`♦ ${networkName} Merge Fractals`}
        subTitle=""
        style={{ cursor: "pointer" }}
      />
    </a>
  );
}
