/*
Housing Data Cleaning / Manipulation

Skills used:
	Converting Data Types
    Altering Table
    Manipulating String Fields
    Removing Duplicates
*/

CREATE DATABASE NashvilleHousingPortfolioProject;
USE NashvilleHousingPortfolioProject;

SELECT * FROM nashvillehousing
ORDER BY saledate;

-----------------------------------------------------------------------------------------------------------------------------------------------

-- SaleDate column currently as text in dd-mmm-yy format
-- Would like to update column to be datetime field in default format of yyyy-mm-dd

SELECT
	CAST(str_to_date(SaleDate, '%d-%b-%y') AS date) as SaleDateConverted
FROM
	NashvilleHousing;

UPDATE
	NashvilleHousing
SET
	SaleDate = CAST(str_to_date(SaleDate, '%d-%b-%y') AS date);
   
-----------------------------------------------------------------------------------------------------------------------------------------------

-- OwnerAddress column is essentially interchangeable with PropertyAddress column now that this is the owner's new address
	-- Will use OwnerAddress column to fill blanks in PropertyAddress column

-- IS NULL returns no results
SELECT *
FROM
	nashvillehousing    
WHERE
	PropertyAddress IS NULL;

SELECT *
FROM
	nashvillehousing    
WHERE
	PropertyAddress = '';

UPDATE
	nashvillehousing
SET
	PropertyAddress = OwnerAddress
WHERE
	PropertyAddress = '';

-- Verify results before and after
SELECT
	COUNT(PropertyAddress)
FROM
	nashvillehousing
WHERE
    PropertyAddress = '';

 -----------------------------------------------------------------------------------------------------------------------------------------------   

-- Breaking out Address into individual columns (Address, City, State)
-- Current format is 'Address, City, State' combined in one field

SELECT
	PropertyAddress
FROM
	nashvillehousing;

SELECT
	-- returns all string up until the first ','
	SUBSTRING(PropertyAddress, 1, Locate(',', PropertyAddress) -1) as Address,
    -- Alternatively: SUBSTRING_INDEX(PropertyAddress, ',', 1) AS Address,
    
    -- returns all string between first ',' and second ','
    SUBSTRING(PropertyAddress, Locate(',', PropertyAddress) + 1 , (Locate(',', PropertyAddress, Locate(',', PropertyAddress) + 1 ) + 1 ) - (Locate(',', PropertyAddress) + 1)) AS City,
    
    -- returns all string after the second ','
    SUBSTRING(PropertyAddress, Locate(',', PropertyAddress, Locate(',', PropertyAddress) + 1 ) + 1 , LENGTH(PropertyAddress)) as State
FROM
	NashvilleHousing;
    
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress char(255),
ADD PropertySplitCity char(255),
ADD PropertySplitState char(255);

ALTER TABLE NashvilleHousing
DROP PropertySplitAddress,
DROP PropertySplitCity,
DROP PropertySplitState;

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, Locate(',', PropertyAddress) -1);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, Locate(',', PropertyAddress) + 1 , (Locate(',', PropertyAddress, Locate(',', PropertyAddress) + 1 ) + 1 ) - (Locate(',', PropertyAddress) + 1));

UPDATE NashvilleHousing
SET PropertySplitState = SUBSTRING(PropertyAddress, Locate(',', PropertyAddress, Locate(',', PropertyAddress) + 1 ) + 1 , LENGTH(PropertyAddress));

-----------------------------------------------------------------------------------------------------------------------------------------------

-- Currently data has some "Yes/No" and some "Y/N" in SoldAsVacant
-- Will standardize this column as "Yes/No"

SELECT
	Distinct(SoldAsVacant),
    Count(SoldAsVacant)
FROM
	nashvillehousing
GROUP BY
	SoldAsVacant;

Select SoldAsVacant,
CASE
	When SoldAsVacant = 'Y' THEN 'Yes'
	When SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
From NashvilleHousing;

Update NashvilleHousing
	SET SoldAsVacant = CASE
		When SoldAsVacant = 'Y' THEN 'Yes'
		When SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END;
        
-----------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY
		ParcelID
	ORDER BY
		UniqueID
		) row_num
FROM NashvilleHousing
)

SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

-----------------------------------------------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

ALTER TABLE
	NashvilleHousing
DROP COLUMN
	OwnerAddress,
DROP COLUMN
    TaxDistrict,
DROP COLUMN
    PropertyAddress,
DROP COLUMN
    SaleDate;

