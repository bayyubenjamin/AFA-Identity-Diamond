// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AggregatorV3Interface
 * @dev Interface for interacting with Chainlink's data feeds.
 * This is a standard interface provided by Chainlink.
 */
interface AggregatorV3Interface {
  /**
   * @notice Returns the number of decimals used in the price feed.
   */
  function decimals() external view returns (uint8);

  /**
   * @notice Returns a description of the data feed.
   */
  function description() external view returns (string memory);

  /**
   * @notice Returns the version number of the data feed.
   */
  function version() external view returns (uint256);

  /**
   * @notice Returns the round data for the given round ID.
   * @param _roundId The ID of the round to retrieve.
   */
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  /**
   * @notice Returns the latest round data.
   */
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}
