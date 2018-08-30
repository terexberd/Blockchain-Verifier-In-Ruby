require 'flamegraph'

# Billcoin Ruby Application
# Jay Berdimuratov & Alex George
class Billcoin
  def initialize(line_num, previous_hash, previous_time)
    @line_num = line_num
    @previous_hash = 0
    @previous_time = [0, 0]
    @actual_previous_time = previous_time
    @users = {}
    @actual_previous_hash = previous_hash
    @negative_balance_checker = 0
    @balance_is_negative = {}
  end

  def timing_verify(split_line)
    time = split_line[3].split('.')
    time[0] = time[0].to_i
    time[1] = time[1].to_i
    if @previous_time[0] > time[0].to_i
      puts "Line #{split_line[0]}: Previous timestamp #{@actual_previous_time} >= new timestamp #{split_line[3]}"
      abort 'BLOCKCHAIN INVALID'
    elsif @previous_time[0] == time[0]
      if @previous_time[1] > time[1]
        puts "Line #{split_line[0]}: Previous timestamp #{@actual_previous_time} >= new timestamp #{split_line[3]}"
        abort 'BLOCKCHAIN INVALID'
      end
    end
    @previous_time = time
    @actual_previous_time = split_line[3]
  end

  def count_verify(split_line)
    if split_line[0].to_i != @line_num
      puts "Line #{@line_num}: Invalid block number #{split_line[0]}, should be #{@line_num}"
      abort('BLOCKCHAIN INVALID')
    end
    @line_num += 1
  end

  def hash_verify(split_line)
    if @previous_hash != split_line[1].to_i(16)
      puts "Line #{split_line[0]}: Previous hash was #{split_line[1]}, should be #{@actual_previous_hash}"
      abort('BLOCKCHAIN INVALID')
    else
      @previous_hash = split_line[4].delete("\n").to_i(16)
      @actual_previous_hash = split_line[4].delete("\n")
    end
  end

  def trader_billcoin(traders)
    trader1 = traders[0]
    transaction_half = traders[1].split('(')
    trader2 = transaction_half[0]
    num_billcoins = transaction_half[1].split(')')
    transaction = [trader1, trader2, num_billcoins[0].to_i]
    update_everything transaction
  end

  def update_everything(transaction)
    account_name transaction
    update_sender transaction
    update_receiver transaction
  end

  def account_name(transaction)
    if transaction[0].length > 6
      abort('Invalid Account Name')
    elsif transaction[1].length > 6
      abort('Invalid Account Name')
    end
  end

  def update_sender(transaction)
    billcoins_traded = transaction[2]
    if transaction[0] != 'SYSTEM'
      account_withdraw(transaction[0], billcoins_traded)
      update_negative transaction[0]
    end
  end

  def update_receiver(transaction)
    billcoins_traded = transaction[2]
    account_deposit(transaction[1], billcoins_traded)
    update_negative transaction[1]
  end

  def update_negative(the_account)
    if @users[the_account] < 0
      @balance_is_negative[the_account] = true
      @negative_balance_checker += 1
    elsif @balance_is_negative[the_account]
      @negative_balance_checker -= 1
      @balance_is_negative[the_account] = false
    end
  end

  def account_withdraw(the_account, billcoins_traded)
    if @users[the_account].nil?
      @users[the_account] = -billcoins_traded
      [true, @users[the_account]]
    else
      @users[the_account] -= billcoins_traded
      [false, @users[the_account]]
    end
  end

  def account_deposit(the_account, billcoins_traded)
    if @users[the_account].nil?
      @users[the_account] = billcoins_traded
      [true, @users[the_account]]
    else
      @users[the_account] += billcoins_traded
      [false, @users[the_account]]
    end
  end

  def hash_check(split_line)
    hash_val = 0
    character_values = "#{split_line[0]}|#{split_line[1]}|#{split_line[2]}|#{split_line[3]}".unpack('U*')
    character_values.each do |character|
      hash_val += (character**2000) * ((character + 2)**21) - ((character + 5)**3)
    end
    hash_val = hash_val % 65_536
    if hash_val.to_s(16) != split_line[-1].delete("\n")
      stringdisplay = "String '#{split_line[0]}|#{split_line[1]}|#{split_line[2]}|#{split_line[3]}' hash set to "
      puts "Line #{split_line[0]}: #{stringdisplay}#{split_line[-1].delete("\n")}, should be #{hash_val.to_s(16)}"
      abort('BLOCKCHAIN INVALID')
    end
  end

  def start(blockchain)
    if File.file?(blockchain)
      threads = []
      File.readlines(blockchain).each do |line|
        split_line = line.split('|')
        count_verify split_line
        timing_verify split_line
        hash_verify split_line
        threads.push(Thread.new { hash_check split_line })
        sleep(0.01)

        transactions = split_line[2].split(':')
        transactions.each do |traders|
          traders = traders.split('>')
          trader_billcoin traders
        end
        next unless @negative_balance_checker > 0
        @users.each do |account, billcoins|
          if billcoins < 1
            puts "Line #{split_line[0]}: Invalid block, address #{account} has #{billcoins} billcoins!"
            abort('BLOCKCHAIN INVALID')
          end
        end
      end
      threads.each(&:join)
      @users.each do |account, billcoins|
        puts "#{account}: #{billcoins} billcoins"
      end
    else
      abort('No such file exists')
    end
  end
  Flamegraph.generate('verifier.html') do
    if !ARGV.empty?
      verifier = Billcoin.new(0, 0, [0, 0])
      verifier.start ARGV[0]
    else
      raise('No file specified')
    end
  end
end
