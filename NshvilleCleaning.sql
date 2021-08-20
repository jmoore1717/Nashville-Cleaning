
-- Cleaning housing data
SELECT * 
FROM PortfolioProject..NashvilleHousing

-- Standardize date format
SELECT SaleDate, CONVERT(Date, SaleDate) -- Use if date is not in desired format
FROM PortfolioProject..NashvilleHousing

-- UPDATE NashvilleHousing
-- SET SaleDate = CONVERT(Date, SaleDate)

-- OR

-- ALTER TABLE NashvilleHousing
-- ADD SaleDateConverted Date;

-- UPDATE NashvilleHousing
-- SET SaleDateConverted = CONVERT(Date, SaleDate)

-- POPULATE PROPERTY ADDRESS DATA
SELECT *
FROM PortfolioProject..NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID -- each address has matching parcel ID, so null address has parcel ID that can be matched

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a 
JOIN PortfolioProject..NashvilleHousing b 
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL


Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null

UPDATE a -- replacing nulls with address, now look to query above and you'll find that there are no null address' left
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress) -- instead of b.PropertyAddress you could put a string like 'No Address'
FROM PortfolioProject..NashvilleHousing a 
JOIN PortfolioProject..NashvilleHousing b 
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID 
WHERE a.PropertyAddress IS NULL 

-- Breaking out address into individual columns... Address, City, State 
SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing -- comma is the delimiter
-- we're going to seperate this using a substring and a character index

-- Splitting the property address up (Address, City) -> Using substrings
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address, -- 1 is the starting position, char index is searching for specific value -> we're looking for a comma, could search 'John' etc.
CHARINDEX(',', PropertyAddress) -- just included this to see the character index, the -1 goes one index left and removes the comma 
FROM PortfolioProject..NashvilleHousing

-- Adding a line to get the city on it's own
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City -- +1 now looks to the right of the comma
FROM PortfolioProject..NashvilleHousing

-- Adding our new columns to the original table
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

SELECT *
FROM PortfolioProject..NashvilleHousing -- Now both new columns are added


-- Splitting the owner address up (Address, City, State) -> using PARSENAME, more efficient
SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 3), -- PARSENAME looks for periods only, we have to replace the commas with periods...
PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 1)
FROM PortfolioProject..NashvilleHousing

-- Now we need to add the new columns to the orginal table
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',' , '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT * 
FROM PortfolioProject..NashvilleHousing

-- Changing Y and N to Yes and No in Sold as vacant column
SELECT DISTINCT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing -- some are yes, no, some are y, n

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

-- Using a case statement
SELECT SoldAsVacant, 
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END
FROM PortfolioProject..NashvilleHousing

UPDATE NashvilleHousing -- updating the table
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END


-- Removing duplicates... doesn't get used too often -> using row number (simplest), could use rank 
-- using a CTE

-- finding which observations are duplicates
WITH RowNumCTE AS(
SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY ParcelID,
                     PropertyAddress,
                     SalePrice,
                     SaleDate,
                     LegalReference
                     ORDER BY
                        UniqueID
    ) row_num
FROM PortfolioProject..NashvilleHousing
--ORDER BY ParcelID 
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

-- deleting the duplicate observations
WITH RowNumCTE AS(
SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY ParcelID,
                     PropertyAddress,
                     SalePrice,
                     SaleDate,
                     LegalReference
                     ORDER BY
                        UniqueID
    ) row_num
FROM PortfolioProject..NashvilleHousing
--ORDER BY ParcelID 
)
DELETE
FROM RowNumCTE
WHERE row_num > 1 -- go back and check the above querie... no more duplicates 


-- Deleting unused columns (if you wanna remove a column from a view)... never remove columns from original database... this is just for practice
-- let's remove the old address' that weren't split
SELECT *
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

