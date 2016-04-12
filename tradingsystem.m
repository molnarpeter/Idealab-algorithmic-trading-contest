function orders = tradingsystem(fund, capital, commission)  
    % This function contains the tradingsystem logic.
    % Feel free to modify and improve evey part of it.
    
    % Preperations
    markets = fieldnames(fund);
    numMarkets = size(markets,1);
    tradingDays = size(fund.(markets{1}).date,1);
    

%%%%%%%%%%%%%%% TRADING LOGIC BLOCK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                                                                                                     %
% in this Block you can code the indicators.                                                                         %
                                                                                                                     %
% the data vectors (f.e. high) are accessed by < fund.(markets{j}).high >                                            %
                                                                                                                     %
% Of course, you can also write your own (maybe simpler) routine to generate the order-file. Just make sure          %
% your algorithm is clear and the order-file it outputs looks the one outputted by writeorders.m. You can then       %   
% evaluate your systems using evaluate.m.                                                                            %
                                                                                                                     %
    % Compute the indicators                                                                                         %
    for j = 1:numMarkets                                                                                             %
                                                                                                                     %
                                                                                                                     %
                                                                                                                     %
        period=14;                                                                                                   %
        observ=tradingDays;                                                                                          %
        
        % Typical Price
        tp = ( fund.(markets{j}).high+ fund.(markets{j}).low+ fund.(markets{j}).close)/3;
        
        % Up or Down
        upordn = ones(observ-1,1);
        upordn(tp(2:observ) <= tp(1:observ-1)) = -1;
        
        % Raw Money Flow
        rmf = tp(2:observ).* fund.(markets{j}).vol(2:observ);
        
        % Positive Money Flow
        pmf = zeros(observ-1,1);
        pmf(upordn == 1) = rmf(upordn == 1);
        
        % Negative Money Flow
        nmf = zeros(observ-1,1);
        nmf(upordn == -1) = rmf(upordn == -1);
        
        % Cumulative sum of end indices
        % Output looks like:
        % [1 16 31 46 61 76 91 ... ]
        temp_var1 = cumsum([1;(period:observ-1)'-(1:observ-period)'+1]);
        % Vector of moving indices
        % Output looks like:
        % [1 2 3 4 5 2 3 4 5 6 3 4 5 6 7 4 5 6 7 8 ... ]
        temp_var2 = ones(temp_var1(observ-period+1)-1,1);
        temp_var2(temp_var1(1:observ-period)) = 2-period;
        temp_var2(1) = 1;
        temp_var2 = cumsum(temp_var2);
        
        % Money Flow Ratio
        mfr = sum(pmf(reshape(temp_var2,period,observ-period)),1)'./ ...
            sum(nmf(reshape(temp_var2,period,observ-period)),1)';
        mfr = [nan(period,1); mfr];
        
        % Money Flow Index
         fund.(markets{j}).mfi = 100-100./(1+mfr);
        
        % Frequency
        observ=tradingDays;
        
        freq = diff(fund.(markets{j}).date);
        
        % Reassign open, high, low, and close based on frequency
        temp_var1 = unique(freq);
        num_dates = length(temp_var1);
        new_open  = nan(observ,1);
        new_high  = nan(observ,1);
        new_low   = nan(observ,1);
        new_close = nan(observ,1);
        for i1 = 2:num_dates
            last_per = freq == temp_var1(i1-1);
            this_per = freq == temp_var1(i1);
            temp_var2 = fund.(markets{j}).open(last_per);
            new_open (this_per) = temp_var2(1);
            new_high (this_per) = max(fund.(markets{j}).high(last_per));
            new_low  (this_per) = min(fund.(markets{j}).low(last_per));
            temp_var2 = fund.(markets{j}).close(last_per);
            new_close(this_per) = temp_var2(end);
        end
        
        X = nan(observ,1);
                temp_var1 = new_high+2*new_low+new_close;
                temp_var2 = 2*new_high+new_low+new_close;
                temp_var3 = new_high+new_low+2*new_close;
                X(new_close < new_open)  = temp_var1(new_close < new_open);                                          %
                X(new_close > new_open)  = temp_var2(new_close > new_open);                                          %
                X(new_close == new_open) = temp_var3(new_close == new_open);                                         %
                pivot = X/4;                                                                                         %
                fund.(markets{j}).sprt  = X/2-new_high;                                                              %
                fund.(markets{j}).res   = X/2-new_low;                                                               %
                                                                                                                     %
        fund.(markets{j}).longEntry     = fund.(markets{j}).mfi < 20;   % long condition                             %
        fund.(markets{j}).shortEntry    = fund.(markets{j}).mfi > 80;   % short condition                            %
                                                                                                                     %
        fund.(markets{j}).longExit      = fund.(markets{j}).res < fund.(markets{j}).close;  % long exit condition    %
        fund.(markets{j}).shortExit     = fund.(markets{j}).sprt > fund.(markets{j}).close; % short exit condition   %
                                                                                                                     %
                                                                                                                     %
        % prepare the equitycurve                                                                                    %  
        fund.(markets{j}).equity = zeros(size(fund.(markets{j}).date));                                              %
                                                                                                                     %
        % Lag the indicitors by one period to avoid forward looking:                                                 %
        %(Todays close mustn't be part of todays trading decision at the open.)                                      %
        fund.(markets{j}).longEntry   = [NaN; fund.(markets{j}).longEntry(1:end-1)];                                 %
        fund.(markets{j}).shortEntry  = [NaN; fund.(markets{j}).shortEntry(1:end-1)];                                %
                                                                                                                     %
        fund.(markets{j}).longExit   = [NaN; fund.(markets{j}).longExit(1:end-1)];                                   %
        fund.(markets{j}).shortExit  = [NaN; fund.(markets{j}).shortExit(1:end-1)];                                  %
    end                                                                                                              %
                                                                                                                     %
% for your entries, you should have defined the logical vectors < fund.(markets{j}).longEntry > and                  %
% < fund.(markets{j}).shortEntry > at this point and be able to run the program.                                     %                                       
                                                                                                                     %
% for your exits, you should have defined the logical vectors < fund.(markets{j}).longExit > and                     %
% < fund.(markets{j}).shortExit > at this point and be able to run the program.                                      %                                       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
    % Money management: Each asset gets the same amount of money in the beginning
    capitalPerShare = floor(ones(numMarkets,1) .* (capital / numMarkets));
    currentPosition = zeros(numMarkets,1);
    unusedCapital   = capital - sum(sum(capitalPerShare));
    
    % Create structure for orders
    orders = {};
    orders.date = [];
    orders.symbol = {};
    orders.entry = [];
    orders.type = {};
    orders.quantity = [];
    
    % Generate orders and keep track of investments and the equity curve
    for j = 1:tradingDays % loop over time
        for k = 1:numMarkets % loop over markets
            if fund.(markets{k}).longExit(j) == true
                if currentPosition(k) > 0 % currently long invested
                    % close the long position
                    % new capital for this stock:
                    % left capital + current value of stock - commission
                    capitalPerShare(k) = capitalPerShare(k) + currentPosition(k) * fund.(markets{k}).open(j) * (1-commission);
                    % Generate order
                    orders.date(end+1)     = fund.(markets{k}).date(j); % when
                    orders.symbol{end+1}   = (markets{k});              % what market
                    orders.entry(end+1)    = 0;                         % 0: it's an exit
                    orders.type{end+1}     = 'l';                       % 'l': short
                    orders.quantity(end+1) = currentPosition(k);        % number of stocks
                    % update current investment state in stock k to 0
                    currentPosition(k) = 0;
                end
            end
            
            if fund.(markets{k}).shortExit(j) == true
                if currentPosition(k) < 0 % currently short invested
                    % close the short position
                    % new capital for this stock:
                    % left capital + current value of stock - commission
                    capitalPerShare(k) = capitalPerShare(k) + currentPosition(k) * fund.(markets{k}).open(j) * (1+commission); % currentPosition is negative, capital decreases
                    % Generate order
                    orders.date(end+1)     = fund.(markets{k}).date(j); % when
                    orders.symbol{end+1}   = (markets{k});              % what market
                    orders.entry(end+1)    = 0;                         % 0: it's an exit
                    orders.type{end+1}     = 's';                       % 's': short
                    orders.quantity(end+1) = -currentPosition(k);       % number of stocks
                    % update current investment state in stock k to 0
                    currentPosition(k) = 0;
                end
            end  
        
            if fund.(markets{k}).longEntry(j) == true % Long signal
                if currentPosition(k) == 0 % currently not long invested
                    currentPosition(k) = floor(capitalPerShare(k) / ((1+commission) * (fund.(markets{k}).open(j)))); % Buy as many stocks as possible
                    capitalPerShare(k) = capitalPerShare(k) - currentPosition(k) * fund.(markets{k}).open(j) * (1+commission); % Update capital
                    % Generate order
                    orders.date(end+1)     = fund.(markets{k}).date(j); % when
                    orders.symbol{end+1}   = (markets{k});              % what market
                    orders.entry(end+1)    = 1;                         % 1: it's an entry
                    orders.type{end+1}     = 'l';                       % 'l': long
                    orders.quantity(end+1) = currentPosition(k);        % number of stocks
                end
            end
            
            if fund.(markets{k}).shortEntry(j) == true % Short signal
                if currentPosition(k) == 0 % currently not short invested
                    currentPosition(k) = -floor(capitalPerShare(k) / ((1+commission) * (fund.(markets{k}).open(j)))); % Buy as many stocks short as possible
                    capitalPerShare(k) = capitalPerShare(k) - currentPosition(k) * fund.(markets{k}).open(j) * (1-commission); % Update capital, capital increases, since currentPosition(k) is neg.
                    % Generate order
                    orders.date(end+1)     = fund.(markets{k}).date(j); % when
                    orders.symbol{end+1}   = (markets{k});              % what market
                    orders.entry(end+1)    = 1;                         % 1: it's an entry
                    orders.type{end+1}     = 's';                       % 's': short
                    orders.quantity(end+1) = -currentPosition(k);       % number of stocks
                end
            end             
            
            
            fund.(markets{k}).equity(j) = capitalPerShare(k) + currentPosition(k) * fund.(markets{k}).open(j) - (commission) * abs(currentPosition(k)) * fund.(markets{k}).open(j);
            if isnan(fund.(markets{k}).equity(j))
                if j > 1
                    fund.(markets{k}).equity(j) = fund.(markets{k}).equity(j-1);
                else
                    fund.(markets{k}).equity(j) = capitalPerShare(k);
                end
            end 
        end
    end
    
    % Compute portfolio equity and score and plot curve
    equity = fund.(markets{1}).equity + unusedCapital;
    for k = 2:numMarkets 
        equity = equity + fund.(markets{k}).equity;
    end
    
    figure('Name', 'Equity curve', 'NumberTitle', 'off');
    plot(equity);
    disp(['Equity: ' num2str(equity(end))]);
    disp([' Score: ' num2str(scoreme(equity))]);
end
