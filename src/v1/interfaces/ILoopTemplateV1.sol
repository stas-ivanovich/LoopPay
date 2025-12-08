// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ILoopTemplateV1 {
    event LoopTemplateCreated(
        uint256 indexed templateId,
        address indexed merchant,
        uint256 baseAmount,
        uint256 periodSeconds
    );

    event LoopTemplatePaused(uint256 indexed templateId, uint256 timestamp);
    event LoopTemplateResumed(uint256 indexed templateId, uint256 timestamp);

    function createLoopTemplate(
        address merchant,
        uint256 baseAmount,
        uint256 periodSeconds,
        string calldata metadataRef
    ) external returns (uint256);

    function getLoopTemplate(uint256 templateId)
        external
        view
        returns (
            address merchant,
            uint256 baseAmount,
            uint256 periodSeconds,
            string memory metadataRef,
            uint256 createdAt,
            uint256 lastUpdatedAt,
            bool active
        );

    function pauseLoop(uint256 templateId) external;
    function resumeLoop(uint256 templateId) external;
}
