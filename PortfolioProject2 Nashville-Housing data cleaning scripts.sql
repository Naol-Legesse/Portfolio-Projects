

-----------------------------------------------------Nashville housing Project-----------------------------------------------------------------
-- # This data shows a bunch of rows of transactions identified by UniqueID, ParcelID, Saledate, PropertyAddress, OwnerAddress and so many more identifiers.
	-- let's see the overview of the table, clean it and make it easier and nicer to see and use.

--1) Overview of the whole data in the table

select * from PortfolioProject..NashvilleHousing




--2) standardize date format

	--This is because the Saledate column in the table is in "datetime" type rather than just "date" so the time part is really irrelevant and ugly to work with
    --So either modify the table column 'Saledate' from datetime to date, under the DATABASE>PortfolioProject>TABLES>NashvilleHousing in the "objects explorer" menu or
    --convert it to date with: 
	    --update NashvilleHousing
	    --set saledate = convert(date,saledate)




--3) populate property address data

    --On the table there are null cells of property address for some uniqueIDs but the same cells have address under another unique ID. so the property address info
		--must be populated
	--This can be done by joining the table with itself on same ParcelID but different UniqueID so that the propertyaddress info can be populated from the other UniqueID
	
select A.ParcelID,A.PropertyAddress,B.ParcelID,B.PropertyAddress, ISNULL(A.PropertyAddress,B.PropertyAddress)
from portfolioProject..Nashvillehousing A join portfolioProject..Nashvillehousing B
	on A.ParcelID=B.ParcelID
	and A.[UniqueID ]<>B.[UniqueID ]
where A.PropertyAddress is null
--in the above code "ISNULL(A.PropertyAddress,B.PropertyAddress)" is used that to see what we are filling instead of the empty cells under PropertyAddress


--And now the table is updated (Alias of the tables are used when updating data using the join)

update A
set PropertyAddress=ISNULL(A.PropertyAddress,B.PropertyAddress)
from portfolioProject..Nashvillehousing A join portfolioProject..Nashvillehousing B
	on A.ParcelID=B.ParcelID
	and A.[UniqueID ]<>B.[UniqueID ]
where A.PropertyAddress is null

--let's check if there are still null cells under property address
select ParcelID,[UniqueID ],PropertyAddress from PortfolioProject..NashvilleHousing
where PropertyAddress is null




--4) breaking out address into individual columns (Address, city, state)
	--# here the "PropertyAddress" and "OwnerAddress" columns show address, city and state all on the same cell, separated with commas. And it's better to split the data 
		--into individual address, city and state.

    -- N.B. use parsename to break into two but it must be changed to period since parsename cant recognize comma
	-- N.B. Parsename splits-out the data found after the period on the right-most end

    -- 4.1) break "propertyaddress" into address and city

select parsename (replace(propertyaddress,',','.'),2) as address,
parsename (replace(propertyaddress,',','.'),1) as city
from PortfolioProject..NashvilleHousing

        -- now create new columns in the table for the new split property address and insert the data
alter table portfolioproject..nashvillehousing
add PropertySplitAddress nvarchar(50)

update PortfolioProject..NashvilleHousing
set PropertySplitAddress = parsename (replace(propertyaddress,',','.'),2)

alter table portfolioproject..nashvillehousing
add PropertySplitCity nvarchar(50)

update PortfolioProject..NashvilleHousing
set PropertySplitCity = parsename (replace(propertyaddress,',','.'),1)


    -- 4.2) break owner address into address, city and state
		--# here the OwnerAddress data shows address, city and state all on the same cell, separated with commas. And it's better to split the data into individual
			--address, city and state.
	
		-- N.B. use parsename to break into two but it must be changed to period since parsename cant recognize comma
		-- N.B. Parsename splits-out the data found after the period on the right-most end
		-- let's replace the commas with period first to make the parsename step easier (easier than the above process of splitting PropertyAddress)

update PortfolioProject..NashvilleHousing
set OwnerAddress = REPLACE(OwnerAddress,',','.')

select
PARSENAME(OwnerAddress,1) as state,
PARSENAME(OwnerAddress,2) as city,
PARSENAME(OwnerAddress,3) as address
from PortfolioProject..NashvilleHousing

        -- now create new columns in the table for the new split owner address and insert the data

alter table PortfolioProject..NashvilleHousing
add OwnerSplitAddress nvarchar(50)
update PortfolioProject..NashvilleHousing
set OwnerSplitAddress = PARSENAME(OwnerAddress,3)


alter table PortfolioProject..NashvilleHousing
add OwnerSplitcity nvarchar(50)
update PortfolioProject..NashvilleHousing
set OwnerSplitCity = PARSENAME(OwnerAddress,2)


alter table PortfolioProject..NashvilleHousing
add OwnerSplitState nvarchar(50)
update PortfolioProject..NashvilleHousing
set OwnerSplitState = PARSENAME(OwnerAddress,1)

select * from PortfolioProject..NashvilleHousing




--5) change Y and N into Yes and No in 'Sold as vacant' field
	--#The "SoldasVacanat" column is supposed to have cells with "Yes" or "No" type data. There are some cells that have "Y" or "N" so they have to be changed 
		-- to "Yes" or "No"

	--here it is also possible to show how many of these wrong cells are in the table
select SoldAsVacant,COUNT(SoldAsVacant) from PortfolioProject..NashvilleHousing
group by SoldAsVacant
order by 2

	--create a case for how to replace the wrong data and compare
select SoldAsVacant,
case when soldasvacant = 'N' then 'No'
	when soldasvacant = 'Y' then 'Yes'
	else SoldAsVacant
	end
from PortfolioProject..NashvilleHousing

	--And now update the table with the new data
update PortfolioProject..NashvilleHousing
set SoldAsVacant = 
case when soldasvacant = 'N' then 'No'
	when soldasvacant = 'Y' then 'Yes'
	else SoldAsVacant
	end
from PortfolioProject..NashvilleHousing




--6) remove duplicates
--#There are rows containing the same data in every column except for the uniqueID. It's not impossible that the data is for two different genuine transactions but it's
	--highly likely that a different uniqueID is given for the same transaction and recorded twice. Those duplicated rows are removed as follows.
	--it's better to use CTE here since it is easier (given that the parcelID, Saledate, PropertyAddress... are similar)

with CTE_DuplicateRow as
(
select *, ROW_NUMBER() over (partition by parcelID,propertyaddress,saledate,saleprice,legalreference 
order by parcelID) as RowNumber
from PortfolioProject..NashvilleHousing
)
delete
from CTE_DuplicateRow
where RowNumber >1

	--check with "select *" where RowNumber >1 to see if there are any duplicates still remaining




--7) delete unused columns
--# The PropertyAddress and OwnerAddress columns are useless now that they are split into individual columns, as shown above. The TaxDistrict column somehow looked useless
	--to me

alter table PortfolioProject..NashvilleHousing
drop column Propertyaddress,Owneraddress,taxdistrict

--check after deletion
select * from PortfolioProject..NashvilleHousing