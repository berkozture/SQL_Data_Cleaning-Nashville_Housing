SELECT
    *
FROM
    Nashville_Housing.NashvilleScheme.Nashville_Housing

--------------------------------------------------------------------------------------------------------------------------
-- Standardize Date Format

UPDATE
    Nashville_Housing.NashvilleScheme.Nashville_Housing
SET
    SaleDate = CONVERT(Date,SaleDate)


 --------------------------------------------------------------------------------------------------------------------------
-- Populate Property Address data

-- Some PropertyAddress values are NULL
SELECT
    PropertyAddress,
    ParcelID
FROM
    Nashville_Housing.NashvilleScheme.Nashville_Housing
WHERE
    PropertyAddress IS NULL


-- There are duplicate Parcel ID values.
-- There are a multiple number of cases where it is duplicated for 2, 3 or even for 4 times.
WITH new_table AS (
    SELECT
        COUNT(*) AS Number_Of_Duplicates,
        ParcelID
    FROM
        Nashville_Housing.NashvilleScheme.Nashville_Housing
    GROUP BY
        ParcelID
)
SELECT
    Number_Of_Duplicates,
    COUNT(*) AS Cases
FROM
    new_table
GROUP BY
    Number_Of_Duplicates
ORDER BY
    Number_Of_Duplicates


-- If a Property Address is null, we can populate it using its duplicate entry (if it has a duplicate Parcel ID value).
-- We can use a JOIN operation to populate the null fields in Property Address column.
UPDATE
    a
SET
    PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM
    Nashville_Housing.NashvilleScheme.Nashville_Housing a
JOIN
    Nashville_Housing.NashvilleScheme.Nashville_Housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE
    a.PropertyAddress IS NULL

--------------------------------------------------------------------------------------------------------------------------
-- Breaking out Address into Individual Columns (Address, City, State)

-- The property address constitutes of various details (City Name, State Name etc.)
-- We would like to break these code into individual columns
-- Here, the delimiter is a comma
SELECT
    PropertyAddress
FROM
    Nashville_Housing.NashvilleScheme.Nashville_Housing


SELECT
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address,
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as Address
FROM
    Nashville_Housing.NashvilleScheme.Nashville_Housing


ALTER TABLE Nashville_Housing.NashvilleScheme.Nashville_Housing
ADD PropertySplitAddress Nvarchar(255);

UPDATE Nashville_Housing.NashvilleScheme.Nashville_Housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )



ALTER TABLE Nashville_Housing.NashvilleScheme.Nashville_Housing
ADD PropertySplitCity Nvarchar(255);

UPDATE Nashville_Housing.NashvilleScheme.Nashville_Housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))


SELECT TOP 10
    *
FROM
    Nashville_Housing.NashvilleScheme.Nashville_Housing


-- Repeating the same procedure for Owner addresses
-- BUT, we will use PARSENAME this time
SELECT
    OwnerAddress
FROM
    Nashville_Housing.NashvilleScheme.Nashville_Housing


ALTER TABLE Nashville_Housing.NashvilleScheme.Nashville_Housing
ADD OwnerSplitAddress Nvarchar(255);
UPDATE Nashville_Housing.NashvilleScheme.Nashville_Housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE Nashville_Housing.NashvilleScheme.Nashville_Housing
ADD OwnerSplitCity Nvarchar(255);
UPDATE Nashville_Housing.NashvilleScheme.Nashville_Housing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)


ALTER TABLE Nashville_Housing.NashvilleScheme.Nashville_Housing
ADD OwnerSplitState Nvarchar(255);
UPDATE Nashville_Housing.NashvilleScheme.Nashville_Housing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)


SELECT *
FROM Nashville_Housing.NashvilleScheme.Nashville_Housing

--------------------------------------------------------------------------------------------------------------------------
-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT TOP 10
    SoldAsVacant
FROM
    Nashville_Housing.NashvilleScheme.Nashville_Housing


-- In some cases, the SoldAsVacant column has 'Yes' and 'No' values
-- But in other cases, it has 'Y' and 'N' for values
SELECT
    Distinct(SoldAsVacant),
    Count(SoldAsVacant)
FROM
    Nashville_Housing.NashvilleScheme.Nashville_Housing
GROUP BY
    SoldAsVacant
ORDER BY
    2


UPDATE
    Nashville_Housing.NashvilleScheme.Nashville_Housing
SET
    SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	    WHEN SoldAsVacant = 'N' THEN 'No'
	    ELSE SoldAsVacant
	    END

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remove Duplicates

-- We can use Window Functions to Partition a multiple number of columns into a single group.
-- Using this partitioning, we can group each partition into a single Row Number.
-- Here, Row Numbers higher than 1 would give us the duplicates (WHERE row_num > 1)
WITH RowNumCTE AS(
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                ParcelID,
                PropertyAddress,
                SalePrice,
                SaleDate,
                LegalReference
            ORDER BY
                UniqueID
        ) row_num
    FROM
        Nashville_Housing.NashvilleScheme.Nashville_Housing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1

---------------------------------------------------------------------------------------------------------
-- Delete Unused Columns

SELECT
    *
FROM
    Nashville_Housing.NashvilleScheme.Nashville_Housing

ALTER TABLE Nashville_Housing.NashvilleScheme.Nashville_Housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

