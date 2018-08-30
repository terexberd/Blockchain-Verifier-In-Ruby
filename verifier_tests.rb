require 'simplecov'
SimpleCov.start

require 'minitest/autorun'
require_relative 'verifier'

# Minitest for verifier.rb
class BillcoinTests < Minitest::Test
  # Tests if the line count goes up
  def test_count_verify
    # line_num, previous_hash, previous_time
    new_billcoin = Billcoin.new(23, 0, [0, 0])
    split_line = ['23']
    assert_equal 24, new_billcoin.count_verify(split_line)
  end

  # Tests if the line count goes up if the input is a negative number
  def test_count_verify_negative
    # line_num, previous_hash, previous_time
    new_billcoin = Billcoin.new(-1, 0, [0, 0])
    split_line = ['-1']
    assert_equal 0, new_billcoin.count_verify(split_line)
  end

  # Tests if the method is able to return the right hash
  def test_hash_verify
    # line_num, previous_hash, previous_time
    new_billcoin = Billcoin.new('3', 'c72d', [0, 0])
    split_line = ['3', '0', 'SYSTEM>Henry(100)', '1518892051.737141000', '1c12']
    @previous_hash = split_line[4].delete("\n")
    assert_equal @previous_hash, new_billcoin.hash_verify(split_line)
  end

  # Tests if the method is able to return the right hash if the input is empty
  def test_hash_verify_nil
    # line_num, previous_hash, previous_time
    new_billcoin = Billcoin.new(0, 0, [0, 0])
    split_line = ['0', '0', 'SYSTEM>Henry(100)', '1518892051.764563000', "\n"]
    @previous_hash = split_line[4].delete("\n")
    assert_equal @previous_hash, new_billcoin.hash_verify(split_line)
  end

  # Tests if the account name is invalid - longer than 8 characters
  def test_account_name_invalid
    # line_num, previous_hash, previous_time
    new_billcoin = Billcoin.new(0, 0, [0, 0])
    transaction = ['Alexandra']
    assert_raises ('Invalid Account Name') { new_billcoin.check_account_name(transaction) }
  end

  # Tests if the account name is valid - shorter than 8 characters
  def test_account_name_valid
    # line_num, previous_hash, previous_time
    new_billcoin = Billcoin.new(0, 0, [0, 0])
    transaction = %[Tang]
    assert_nil new_billcoin.account_name(transaction)
  end

  # Tests if the method is able to withdraw from an empty balance
  def test_withdraw_from_zero_balance
    # line_num, previous_hash, previous_time
    new_billcoin = Billcoin.new(0, 0, [0, 0])
    the_account = 'George'
    billcoins_traded = 10
    assert_equal [true, -10], new_billcoin.account_withdraw(the_account, billcoins_traded)
    assert_equal [false, -20], new_billcoin.account_withdraw(the_account, billcoins_traded)
  end

  # Tests if the method is able to withdraw from a positive balance
  def test_withdraw_from_positive_balance
    # line_num, previous_hash, previous_time
    new_billcoin = Billcoin.new(0, 0, [0, 0])
    the_account = 'George'
    new_billcoin.account_deposit('George', 100)
    billcoins_traded = 10
    assert_equal [false, 90], new_billcoin.account_withdraw(the_account, billcoins_traded)
    assert_equal [false, 80], new_billcoin.account_withdraw(the_account, billcoins_traded)
  end

  # Tests if the method returns the right time
  def test_timing_verify
    # line_num, previous_hash, previous_time
    new_billcoin = Billcoin.new(0, 0, '152051')
    split_line = ['', '', '', '152051', '']
    assert_equal '152051', new_billcoin.timing_verify(split_line)
  end

  # Tests if the method returns the right time if the input is 0
  def test_timing_verify_zero
    # line_num, previous_hash, previous_time
    new_billcoin = Billcoin.new(0, 0, '0')
    split_line = ['', '', '', '0']
    assert_equal '0', new_billcoin.timing_verify(split_line)
  end

  # Tests if the method returns the right time if the input is a decimal number
  def test_timing_verify_decimals
    # line_num, previous_hash, previous_time
    new_billcoin = Billcoin.new(0, 0, '.12415')
    split_line = ['', '', '', '.12415', '']
    assert_equal '.12415', new_billcoin.timing_verify(split_line)
  end

  # Tests if the method returns nil if Bill's balance is not negative
  def test_update_negative_balance_check
    # line_num, previous_hash, previous_time
    new_billcoin = Billcoin.new(0, 0, [0, 0])
    new_billcoin.account_deposit('Bill', 10)
    assert_nil new_billcoin.update_negative 'Bill'
  end

  # Tests if the the method is able to make a deposit
  def test_account_deposit_positive_number
    # line_num, previous_hash, previous_time
    new_billcoin = Billcoin.new(0, 0, [0, 0])
    the_account = 'James'
    billcoins_traded = 20
    assert_equal [true, 20], new_billcoin.account_deposit(the_account, billcoins_traded)
    assert_equal [false, 40], new_billcoin.account_deposit(the_account, billcoins_traded)
  end

  # Tests if the method is able to deposit a negative number
  def test_account_deposit_negative_number
    # line_num, previous_hash, previous_time
    new_billcoin = Billcoin.new(0, 0, [0, 0])
    the_account = 'George'
    billcoins_traded = -15
    assert_equal [true, -15], new_billcoin.account_deposit(the_account, billcoins_traded)
    assert_equal [false, -30], new_billcoin.account_deposit(the_account, billcoins_traded)
  end
end