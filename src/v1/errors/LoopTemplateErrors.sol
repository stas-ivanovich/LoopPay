// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface LoopTemplateErrors {
    error InvalidMerchant();
    error InvalidAmount();
    error InvalidPeriod();
    error TemplateNotFound();
    error TemplateAlreadyPaused();
    error TemplateAlreadyActive();
    error NotAuthorized();
}
