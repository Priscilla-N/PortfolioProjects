Cleaning Data in SQL Queries
Select *
From PortfolioProject.dbo.NashvilleHousing

-- Standardize Date Format, this is in a date-time format
Select SaleDate
From NashvilleHousing

-- This would create a new column showing only the date
Select SaleDate, Convert(Date, SaleDate)
From NashvilleHousing

-- Now update it
Update NashvilleHousing
Set SaleDate =  Convert(Date, SaleDate)

-- If it doesn't Update properly, do this:
ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

-- Now try to update it again
Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

-- Now try it again, it works
Select SaleDateConverted, Convert(Date, SaleDate)
From NashvilleHousing



-- Now, we want to Populate Property Address data
Select PropertyAddress
From PortfolioProject.dbo.NashvilleHousing

-- Check for NULL values
Select PropertyAddress
From PortfolioProject.dbo.NashvilleHousing
where PropertyAddress is null

(There are some null values in the propertyaddress column. Property address is permanent, but the owner’s address might change. Exploring the data, let’s take a look at the entire table, order it by ParcelID and compare the parcelID with the PropertyAddress column)
Like this:

Select ParcelID, PropertyAddress
From PortfolioProject.dbo.NashvilleHousing
Order by ParcelID

(We see that Parcels with the same ID have the exact same PropertyAddress. Now for every duplicate ParcelID that doesn’t have an Address, we can Populate the already existing PropertyAddress for it because we know it’s going to be the same)-(To do this, we need to do a self-join on this table)

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
From PortfolioProject.dbo.NashvilleHousing a
Join PortfolioProject.dbo.NashvilleHousing b
     On a.ParcelID = b.ParcelID
	
(Since the ParcelID are the same from the same table, we need to filter on a unique Identifier- We have a UniqueID column in the table)

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
From PortfolioProject.dbo.NashvilleHousing a
Join PortfolioProject.dbo.NashvilleHousing b
     On a.ParcelID = b.ParcelID
	 And a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null
 (This would populate the table showing only where the a.PropertyAddress is NULL)

(Now, for everywhere a.PropertyAddress is NULL, we want to replace it with b.PropertyAddress using ISNULL)

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing a
Join PortfolioProject.dbo.NashvilleHousing b
     On a.ParcelID = b.ParcelID
	 And a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null
(This would create an entirely new column showing the PropertyAddress)Now update it.

Update a
Set PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing a
Join PortfolioProject.dbo.NashvilleHousing b
     On a.ParcelID = b.ParcelID
	 And a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null

 Now it has been updated because if you run this again:
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing a
Join PortfolioProject.dbo.NashvilleHousing b
     On a.ParcelID = b.ParcelID
	 And a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null
It would return empty		



-- Next we want to Break out the PropertyAddress into Individual Columns (Address & City)
In here, the Address and City are separated by a Comma which is called a DELIMITER
To separate this, let us first of all use a SubString & A Character Index

Select 
Substring( PropertyAddress, 1, CHARINDEX(',', PropertyAddress) ) as Address
From PortfolioProject.dbo.NashvilleHousing
(This would return a new column called Address with only the first part of PropertyAddress)

Now this Address would show with the comma at the end, but we want to take it out, so we do this:
Select 
Substring( PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
From PortfolioProject.dbo.NashvilleHousing 

Next, we want to create a new column with the separated City Names:
Select 
Substring( PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
, Substring( PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress) ) as Address
From PortfolioProject.dbo.NashvilleHousing

Next we are going to create 2new columns and add the 2new separated values in: 
First, add the new PropertySplitAddress into the NashvilleHousing Table:
ALTER TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar(255); 

Then Update It:
Update NashvilleHousing
SET PropertySplitAddress = Substring( PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

Similarly, also add the new PropertySplitCity into the NashvilleHousing Table:
ALTER TABLE NashvilleHousing
Add PropertySplitCity Nvarchar (255);

Then Update It:
Update NashvilleHousing
SET PropertySplitCity = Substring( PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress) )

Now if you check the table, at the end you would find the 2new created columns:
Select*
From NashvilleHousing



-- Now, we want to Populate Owner Address data
We need to break it up into Address, City and State.
Let’s take a look at the column:
Select OwnerAddress
From NashvilleHousing

To split this, let’s use ParseName this time:
So, ParseName only works with period(.) and not commas(,)
Hence, we need to replace the commas with periods.
Also, take note that Parsename reads backwards, so to have the address first, we go 3,2,1. Like this:

Select
Parsename (Replace(OwnerAddress, ',', '.'), 3)
, Parsename (Replace(OwnerAddress, ',', '.'), 2)
, Parsename (Replace(OwnerAddress, ',', '.'), 1)
From NashvilleHousing
So ParseName is an easier way to separate a column than Substring
Now we need to Update the NashvilleHousing Table with the new columns:
ALTER TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)



ALTER TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)


-- Now, We want to change Y and N to Yes and No in "Sold as Vacant" field
-- To see all the Distinct attributes in this column, we do this:

Select Distinct(SoldAsVacant)
From NashvilleHousing
--We see that this has a mixture of No, Yes, N and Y

--Out of curiosity, let's check how many of the N and Y we have in this column:
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From NashvilleHousing
Group by SoldAsVacant
Order by 2
-- This shows us the number of N, Y, No & Yes in an ascending order
--Now we want to change them all to Yes and No using a CASE statement

Select SoldAsVacant,
Case When SoldAsVacant = 'Y' Then 'Yes'
     When SoldAsVacant = 'N' Then 'No' 
Else SoldAsVacant
End
From NashvilleHousing
--This would create a new column with only Yes and No

(Now, we need to update the new column on the table)
Update NashvilleHousing
SET SoldAsVacant = Case When SoldAsVacant = 'Y' Then 'Yes'
                        When SoldAsVacant = 'N' Then 'No' 
	                 Else SoldAsVacant
	                 End
--Now we can verify again to see what attributes it generates
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From NashvilleHousing
Group by SoldAsVacant
Order by 2


-- Now, we want to Remove Duplicates from the Table
-- We can first write out a query with some window functions to find where there are duplicate values and then put it into a CTE
-- We want to Partition our Data on things that should be Unique to each Row, and Identify duplicate Rows (We would use Row Number)

Select *,
     ROW_NUMBER() OVER (
	 PARTITION BY ParcelID,
	              PropertyAddress,
		       SalePrice,
		       SaleDate,
			LegalReference
	              ORDER BY UniqueID
		          )   row_num

From NashvilleHousing
Order by ParcelID

-- Then check the new column(Row_Num) and find where there are 1&2 showing duplicates
-- Now let's put this into a CTE

WITH RowNumCTE AS(
Select *,
     ROW_NUMBER() OVER (
	 PARTITION BY ParcelID,
	              PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
	              ORDER BY UniqueID
			    )   row_num

From NashvilleHousing
  )
-- Now row_num is a column and we can use it in a query, and it would populate all duplicate rows(Run this with the CTE)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress

-- We can now go ahead to delete the duplicate rows(Run it with the CTE)

WITH RowNumCTE AS(
Select *,
     ROW_NUMBER() OVER (
	 PARTITION BY ParcelID,
	              PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
	              ORDER BY UniqueID
		          )   row_num

From NashvilleHousing
  )

Delete
From RowNumCTE
Where row_num > 1

-- To reconfirm, we can select everything where row_num > 1 to check(There would be no duplicates)
WITH RowNumCTE AS(
Select *,
     ROW_NUMBER() OVER (
	 PARTITION BY ParcelID,
	              PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
	              ORDER BY UniqueID
		          )   row_num

From NashvilleHousing
  )

Select*
From RowNumCTE
Where row_num > 1


-- We want to Delete Unused Columns (Do not delete rows from your main data, you can delete from views)

Select *
From PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

























