require 'time'

module Stats
  def average(info)
    (info.reduce(:+)/info.count.to_f).round(2)
  end

  def variance(info)
    current_av = average(info)
    info.map {|num| (num-current_av)**2}
  end

  def standard_deviation(info)
    average = average(info)
    variance = variance(info)
    Math.sqrt(average(variance)).round(2)
  end

  def invoice_day
    @se.invoices.all.map {|invoice| Date::DAYNAMES[(invoice.created_at).wday]}
  end

  def top_days_via_invoices
    total_invoices_by_day = {}
    total_invoices_by_day =  invoice_day.reduce({}) do |val, day|
      val[day] = 0 if val[day].nil?
      val[day] += 1
      val
    end
    total_invoices_by_day
    invoices_by_day = total_invoices_by_day.values
    bar = average(invoices_by_day) + standard_deviation(invoices_by_day)
    top_days = []
    total_invoices_by_day.each { |key, value| top_days << key if value > bar}
    top_days
  end

  def pending_invoices
    total =  @se.invoices.all.length
    pending = 0
    @se.invoices.all.each { |invoice| pending += 1 if invoice.status == "pending"}
    pending_percent = (pending.to_f / total.to_f) * 100
    pending_percent.round(2)
  end

  def shipped_invoices
    total =  @se.invoices.all.length
    shipped = 0
    @se.invoices.all.each { |invoice| shipped += 1 if invoice.status == "shipped"}
    shipped_percent =  (shipped.to_f / total.to_f) * 100
    shipped_percent.round(2)
  end

  def returned_invoices
    total =  @se.invoices.all.length
    returned = 0
    @se.invoices.all.each { |invoice| returned += 1 if invoice.status == "returned"}
    returned_percent =  (returned.to_f / total.to_f) * 100
    returned_percent.round(2)
  end


  def num_items_per_merchant
    merch_ids = merch_id_array
      arr_n_items_by_merch =  []
      merch_ids.each do |id|
      arr_n_items_by_merch << @se.items.find_all_by_merchant_id(id).length
    end
    arr_n_items_by_merch
  end

  def merch_with_num_of_items_hash
    merch_name_array = []
    @se.merchants.all.each do |merch|
      merch_name_array << merch.name
    end
    nested_arr = merch_name_array.zip(num_items_per_merchant)
    hash = Hash[nested_arr]
  end

  def merch_id_array
    merch_id_array = []
    @se.merchants.all.each do |merch|
      merch_id_array << merch.id
    end
    merch_id_array
  end

# for iteration 4: maybe make a merchant analytics module?

  def invoices_by_date_hash
    hash = {}
    find_shipped_invoice_by_date.each do |invoice|
      hash[invoice[0].to_s] = []
    end
    hash.each do |key, value|
      find_shipped_invoice_by_date.each do |invoice|
        value << invoice[1] if key == invoice[0].to_s
      end
    end
  end

  def find_shipped_invoice_by_date
  shipped_invoices =  @se.invoices.find_all_by_status("shipped")
    dates = []
    invoice_ids = []
    shipped_invoices.each do |invoice|
      dates << invoice.created_at
      invoice_ids << invoice.id
    end
    dates.sort!
    invoice_ids.sort
    invoices_by_date = dates.zip(invoice_ids)
  end

  def invoice_ids_per_merchant_id_hash
    invoice_items_per_merchant = []
    merch_id_array.each do |id|
      invoice_items_per_merchant << @se.invoices.find_all_by_merchant_id(id)
    end
    invoice_items_per_merchant
    for_hash = merch_id_array.zip(invoice_items_per_merchant)
    hash = Hash[for_hash]
    hash.map do |key, value|
      spec_ids = []
      value.map { |invoice| spec_ids << invoice.id}
    hash[key] = spec_ids
    hash
    end
    hash
  end

  def merchant_ids_to_revenue_hash #stuck here
      #value become arrays of inoice_item_id, each of those elements is turned into
      #revenue, revenue is then reduced(:+) into a sum
      #this replaces the elements in invoice_ids_per_merchant_id_hash
      #this is then summed to give total reveneuw per merchant
      revenue_hash = {}
      revenue_hash = invoice_ids_per_merchant_id_hash.each_value do |value|
        temp = []
        value.each do |invoice_id|
          temp << @se.invoices.get_invoice_items_for_invoice(invoice_id)
          temp.each do |invoice_item_id|
            invoice_i = @se.invoice_items.find_by_id(invoice_item_id)
            invoice_i.unit_price.to_i * invoice_i.quantity
            end
            var = temp.reduce(:+)
          end
          value
        end

      revenue_hash
    end





end
