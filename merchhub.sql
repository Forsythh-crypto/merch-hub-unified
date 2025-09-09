-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Aug 15, 2025 at 01:01 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `merchhub`
--

-- --------------------------------------------------------

--
-- Table structure for table `cache`
--

CREATE TABLE `cache` (
  `key` varchar(255) NOT NULL,
  `value` mediumtext NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `cache_locks`
--

CREATE TABLE `cache_locks` (
  `key` varchar(255) NOT NULL,
  `owner` varchar(255) NOT NULL,
  `expiration` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`id`, `name`, `created_at`, `updated_at`) VALUES
(1, 'Clothing', '2025-08-14 20:40:00', '2025-08-14 20:40:00'),
(2, 'Accessories', '2025-08-14 20:40:00', '2025-08-14 20:40:00'),
(3, 'Supplies', '2025-08-14 20:40:00', '2025-08-14 20:40:00'),
(4, 'Tech', '2025-08-14 20:40:00', '2025-08-14 20:40:00');

-- --------------------------------------------------------

--
-- Table structure for table `departments`
--

CREATE TABLE `departments` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `logo_path` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `departments`
--

INSERT INTO `departments` (`id`, `name`, `description`, `logo_path`, `created_at`, `updated_at`) VALUES
(1, 'School of Information Technology Education', NULL, 'site.png', '2025-08-14 20:40:00', '2025-08-14 20:47:19'),
(2, 'School of Teacher Education', NULL, 'ste.png', '2025-08-14 20:40:00', '2025-08-14 20:47:19'),
(3, 'School of Criminology', NULL, 'soc.png', '2025-08-14 20:40:00', '2025-08-14 20:47:19'),
(4, 'School of Health Sciences', NULL, 'sohs.png', '2025-08-14 20:40:00', '2025-08-14 20:47:19'),
(5, 'School of Humanities', NULL, 'soh.png', '2025-08-14 20:40:00', '2025-08-14 20:47:19'),
(6, 'School of Engineering', NULL, 'soe.png', '2025-08-14 20:40:00', '2025-08-14 20:47:19'),
(7, 'School of International Hospitality Management', NULL, 'sihm.png', '2025-08-14 20:40:00', '2025-08-14 20:47:19'),
(8, 'School of Business and Accountancy', NULL, 'sba.png', '2025-08-14 20:41:41', '2025-08-14 20:47:19');

-- --------------------------------------------------------

--
-- Table structure for table `failed_jobs`
--

CREATE TABLE `failed_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `uuid` varchar(255) NOT NULL,
  `connection` text NOT NULL,
  `queue` text NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `jobs`
--

CREATE TABLE `jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `attempts` tinyint(3) UNSIGNED NOT NULL,
  `reserved_at` int(10) UNSIGNED DEFAULT NULL,
  `available_at` int(10) UNSIGNED NOT NULL,
  `created_at` int(10) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `job_batches`
--

CREATE TABLE `job_batches` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `total_jobs` int(11) NOT NULL,
  `pending_jobs` int(11) NOT NULL,
  `failed_jobs` int(11) NOT NULL,
  `failed_job_ids` longtext NOT NULL,
  `options` mediumtext DEFAULT NULL,
  `cancelled_at` int(11) DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  `finished_at` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `listings`
--

CREATE TABLE `listings` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `image_path` varchar(255) DEFAULT NULL,
  `department_id` bigint(20) UNSIGNED NOT NULL,
  `category_id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `price` decimal(8,2) NOT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'pending',
  `stock_quantity` int(11) NOT NULL DEFAULT 1,
  `size` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `listings`
--

INSERT INTO `listings` (`id`, `title`, `description`, `image_path`, `department_id`, `category_id`, `user_id`, `price`, `status`, `stock_quantity`, `size`, `created_at`, `updated_at`) VALUES
(1, 'UDD SITE Hoodie', 'Comfortable hoodie with UDD SITE logo', NULL, 1, 1, 1, 850.00, 'approved', 0, 'M', '2025-08-14 20:55:28', '2025-08-15 02:05:38'),
(2, 'UDD Engineering Shirt', 'Classic t-shirt for engineering students', NULL, 1, 1, 1, 450.00, 'approved', 1, 'L', '2025-08-14 20:55:28', '2025-08-14 20:57:38'),
(3, 'UDD Criminology Cap', 'Stylish cap with UDD Criminology design', NULL, 1, 1, 1, 250.00, 'approved', 1, 'One Size', '2025-08-14 20:55:28', '2025-08-14 20:57:38'),
(4, 'UD.', 'ahah', 'listings/2rLiAXHfftq9TCCTysorpqCkN7svEvSSoK0wj9qb.png', 8, 1, 1, 1150.00, 'approved', 1, 'XS', '2025-08-14 20:59:26', '2025-08-14 20:59:26'),
(5, 'shs', 'qw', 'listings/yApJzTNHsXaE7KKVddpnJxoRk1J3UKEq1NKqVSRu.jpg', 3, 1, 1, 100.00, 'approved', 0, 'XS', '2025-08-14 21:26:35', '2025-08-15 02:11:57'),
(6, 'shs', 'qw', 'listings/Iy4si587kA4iHwlShHCKiQCjU77CuauaWo7yHGNQ.jpg', 3, 1, 1, 100.00, 'approved', 1, 'S', '2025-08-14 21:26:35', '2025-08-14 21:26:35'),
(7, 'shs', 'qw', 'listings/RfQ5g335Gr7FVmuwAcswd0G8NoOGgcn3epmA221I.jpg', 3, 1, 1, 100.00, 'approved', 1, 'M', '2025-08-14 21:26:35', '2025-08-14 21:26:35'),
(8, 'shs', 'qw', 'listings/DKZ9ItIna7kWnLg8D25JCokwqJRTaedgfUIaPOtO.jpg', 3, 1, 1, 100.00, 'approved', 1, 'L', '2025-08-14 21:26:35', '2025-08-14 21:26:35'),
(9, 'shs', 'qw', 'listings/kpww40y2rJRrxS8dLXoYTTaKcTXdoVIODVoNvZPt.jpg', 3, 1, 1, 100.00, 'approved', 1, 'XL', '2025-08-14 21:26:35', '2025-08-14 21:26:35'),
(10, 'shs', 'qw', 'listings/djtelHbH9ij92vSUei3dCzTotoAFMfzqVPRvqDnm.jpg', 3, 1, 1, 100.00, 'approved', 1, 'XXL', '2025-08-14 21:26:36', '2025-08-14 21:26:36'),
(11, 'zhs', 'qgq', 'listings/2jc0SvJ4JWeVHI4Hx7pYJyl6OtIawzfdDa5anIf2.jpg', 6, 1, 1, 150.00, 'approved', 1, NULL, '2025-08-14 21:39:09', '2025-08-14 21:39:09'),
(12, 'fff', 'vv', 'listings/uXPTSnrtwu5Vrut18TkO8P2UG022m5snLfzKXkJA.jpg', 4, 1, 1, 200.00, 'approved', 1, NULL, '2025-08-14 21:45:36', '2025-08-14 22:26:05'),
(13, 'test', 'sgsg', 'listings/aPQk8MlZH8sInqc4uYjVA9vcZStzE93d10GeeAJO.jpg', 5, 2, 1, 15.00, 'approved', 0, NULL, '2025-08-14 22:23:34', '2025-08-15 01:28:10'),
(14, 'Udd hoodie site', 'sys', NULL, 1, 1, 7, 150.00, 'approved', 1, NULL, '2025-08-14 23:33:54', '2025-08-14 23:44:53'),
(15, 'Udd haha', 'shshs', 'listings/2ihxdf4XGrMD6mNw9OlDPrtwTENFtz9CmHOrL5pf.jpg', 1, 3, 7, 150.00, 'pending', 1, NULL, '2025-08-14 23:52:35', '2025-08-15 00:03:29'),
(16, 'shsh', 'ww', NULL, 1, 2, 7, 150.00, 'pending', 10, NULL, '2025-08-15 00:05:10', '2025-08-15 00:08:32');

-- --------------------------------------------------------

--
-- Table structure for table `listing_size_variants`
--

CREATE TABLE `listing_size_variants` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `listing_id` bigint(20) UNSIGNED NOT NULL,
  `size` varchar(255) NOT NULL,
  `stock_quantity` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `listing_size_variants`
--

INSERT INTO `listing_size_variants` (`id`, `listing_id`, `size`, `stock_quantity`, `created_at`, `updated_at`) VALUES
(1, 11, 'XS', 0, '2025-08-14 21:39:09', '2025-08-15 01:30:05'),
(2, 11, 'S', 1, '2025-08-14 21:39:09', '2025-08-14 21:39:09'),
(3, 11, 'M', 1, '2025-08-14 21:39:09', '2025-08-14 21:39:09'),
(4, 11, 'L', 1, '2025-08-14 21:39:09', '2025-08-14 21:39:09'),
(5, 11, 'XL', 1, '2025-08-14 21:39:09', '2025-08-14 21:39:09'),
(6, 11, 'XXL', 0, '2025-08-14 21:39:09', '2025-08-15 01:55:48'),
(18, 12, 'XS', 0, '2025-08-14 22:26:05', '2025-08-15 01:13:58'),
(19, 12, 'S', 0, '2025-08-14 22:26:05', '2025-08-15 00:48:51'),
(20, 12, 'M', 0, '2025-08-14 22:26:05', '2025-08-15 00:49:15'),
(21, 12, 'L', 1, '2025-08-14 22:26:05', '2025-08-14 22:26:05'),
(22, 12, 'XL', 2, '2025-08-14 22:26:05', '2025-08-15 01:18:44'),
(23, 12, 'XXL', 4, '2025-08-14 22:26:05', '2025-08-14 22:26:05'),
(30, 14, 'XS', 0, '2025-08-14 23:44:53', '2025-08-15 01:27:16'),
(31, 14, 'S', 0, '2025-08-14 23:44:53', '2025-08-15 02:21:50'),
(32, 14, 'M', 1, '2025-08-14 23:44:53', '2025-08-14 23:44:53'),
(33, 14, 'L', 1, '2025-08-14 23:44:53', '2025-08-14 23:44:53'),
(34, 14, 'XL', 1, '2025-08-14 23:44:53', '2025-08-14 23:44:53'),
(35, 14, 'XXL', 1, '2025-08-14 23:44:53', '2025-08-14 23:44:53');

-- --------------------------------------------------------

--
-- Table structure for table `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(1, '0001_01_01_000001_create_cache_table', 1),
(2, '0001_01_01_000002_create_jobs_table', 1),
(3, '2023_01_01_000000_create_departments_table', 1),
(4, '2023_01_01_000001_create_users_table', 1),
(5, '2023_01_01_000002_create_categories_table', 1),
(6, '2025_08_12_095915_create_personal_access_tokens_table', 1),
(7, '2025_08_12_100834_create_products_table', 1),
(8, '2025_08_12_105758_create_listings_table', 1),
(9, '2025_08_12_105800_create_orders_table', 1),
(10, '2025_08_12_105943_create_reservations_table', 1),
(11, '2025_08_13_123817_add_status_and_stock_to_listings_table', 1),
(12, '2025_08_14_053924_add_description_to_departments_table', 1),
(13, '2025_08_15_000000_add_logo_to_departments_table', 1),
(14, '2025_08_15_052827_create_listing_size_variants_table', 2),
(15, '2025_08_15_081823_add_size_to_orders_table', 3),
(16, '2025_08_15_084722_make_user_id_nullable_in_orders_table', 4),
(17, '2025_08_15_101727_add_email_to_orders_table', 5);

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `order_number` varchar(255) NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `listing_id` bigint(20) UNSIGNED NOT NULL,
  `department_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` int(11) NOT NULL,
  `size` varchar(10) DEFAULT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `status` enum('pending','confirmed','ready_for_pickup','completed','cancelled') NOT NULL DEFAULT 'pending',
  `pickup_date` datetime DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `payment_method` varchar(255) NOT NULL DEFAULT 'cash_on_pickup',
  `email_sent` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `orders`
--

INSERT INTO `orders` (`id`, `order_number`, `user_id`, `email`, `listing_id`, `department_id`, `quantity`, `size`, `total_amount`, `status`, `pickup_date`, `notes`, `payment_method`, `email_sent`, `created_at`, `updated_at`) VALUES
(1, 'ORD-20250815-PVAD5M', NULL, NULL, 12, 4, 1, 'S', 200.00, 'pending', NULL, NULL, 'cash_on_pickup', 0, '2025-08-15 00:48:51', '2025-08-15 00:48:51'),
(2, 'ORD-20250815-ZECKSN', NULL, NULL, 12, 4, 1, 'M', 200.00, 'pending', NULL, NULL, 'cash_on_pickup', 0, '2025-08-15 00:49:15', '2025-08-15 00:49:15'),
(3, 'ORD-20250815-IHGYGM', NULL, NULL, 12, 4, 1, 'XL', 200.00, 'pending', NULL, NULL, 'cash_on_pickup', 0, '2025-08-15 00:51:41', '2025-08-15 00:51:41'),
(4, 'ORD-20250815-FKIAAN', NULL, NULL, 12, 4, 1, 'XS', 200.00, 'pending', NULL, NULL, 'cash_on_pickup', 1, '2025-08-15 01:13:58', '2025-08-15 01:13:59'),
(5, 'ORD-20250815-0JU9IA', NULL, NULL, 12, 4, 2, 'XL', 400.00, 'pending', NULL, NULL, 'cash_on_pickup', 1, '2025-08-15 01:18:44', '2025-08-15 01:18:47'),
(6, 'ORD-20250815-PEAATQ', 8, 'testt@admin.com', 14, 1, 1, 'XS', 150.00, 'pending', NULL, NULL, 'cash_on_pickup', 0, '2025-08-15 01:27:16', '2025-08-15 02:20:26'),
(7, 'ORD-20250815-WZQVLC', 8, 'testt@admin.com', 13, 5, 1, NULL, 15.00, 'pending', NULL, NULL, 'cash_on_pickup', 0, '2025-08-15 01:28:10', '2025-08-15 02:20:26'),
(8, 'ORD-20250815-R2FWHV', 8, 'testt@admin.com', 11, 6, 1, 'XS', 150.00, 'ready_for_pickup', NULL, NULL, 'cash_on_pickup', 1, '2025-08-15 01:30:05', '2025-08-15 02:20:26'),
(9, 'ORD-20250815-IAP46Y', 8, 'testt@admin.com', 11, 6, 1, 'XXL', 150.00, 'pending', NULL, NULL, 'cash_on_pickup', 1, '2025-08-15 01:55:48', '2025-08-15 02:20:26'),
(10, 'ORD-20250815-WRLYAQ', 8, 'testt@admin.com', 1, 1, 1, NULL, 850.00, 'pending', NULL, NULL, 'cash_on_pickup', 1, '2025-08-15 02:05:38', '2025-08-15 02:20:26'),
(11, 'ORD-20250815-SQNYOH', 8, 'testt@admin.com', 5, 3, 1, NULL, 100.00, 'ready_for_pickup', NULL, NULL, 'cash_on_pickup', 1, '2025-08-15 02:11:57', '2025-08-15 02:20:26'),
(12, 'ORD-20250815-BJUQW4', 8, 'forsyth029@gmail.com', 14, 1, 1, 'S', 150.00, 'ready_for_pickup', NULL, NULL, 'cash_on_pickup', 1, '2025-08-15 02:21:50', '2025-08-15 02:22:28');

-- --------------------------------------------------------

--
-- Table structure for table `password_reset_tokens`
--

CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `personal_access_tokens`
--

CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `tokenable_type` varchar(255) NOT NULL,
  `tokenable_id` bigint(20) UNSIGNED NOT NULL,
  `name` text NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `personal_access_tokens`
--

INSERT INTO `personal_access_tokens` (`id`, `tokenable_type`, `tokenable_id`, `name`, `token`, `abilities`, `last_used_at`, `expires_at`, `created_at`, `updated_at`) VALUES
(1, 'App\\Models\\User', 1, 'auth_token', '10e1f4093306641a6646de990049eaae63d13dcf83d6d4917670ee3e3cb7092d', '[\"*\"]', '2025-08-14 21:49:45', NULL, '2025-08-14 20:40:53', '2025-08-14 21:49:45'),
(2, 'App\\Models\\User', 3, 'auth_token', '9cba2bfbdb294f9375dc368f6fb0d2505d427f87ab8e583150f90b8a4cfb461b', '[\"*\"]', '2025-08-14 21:51:09', NULL, '2025-08-14 21:50:18', '2025-08-14 21:51:09'),
(3, 'App\\Models\\User', 2, 'auth_token', '0736a3750d1e3c8cf8afdc859835d75474a9303cbd228296d1c038de5f7bd82d', '[\"*\"]', '2025-08-14 21:52:13', NULL, '2025-08-14 21:52:03', '2025-08-14 21:52:13'),
(4, 'App\\Models\\User', 4, 'auth_token', 'd684cf82043b3ad1254149f69cf0b8b088101d837e2e11b080ea524528bd9131', '[\"*\"]', '2025-08-14 21:52:58', NULL, '2025-08-14 21:52:58', '2025-08-14 21:52:58'),
(5, 'App\\Models\\User', 1, 'auth_token', 'ba6dde815733ed1dff485eaa465e6e8e8aa78c0cb23e45200da346bd661ea8a2', '[\"*\"]', '2025-08-14 21:53:22', NULL, '2025-08-14 21:53:11', '2025-08-14 21:53:22'),
(6, 'App\\Models\\User', 4, 'auth_token', 'bc39ad76247c9d4f49d3151373b29726624450385113c2c8445cecaf2ad58407', '[\"*\"]', '2025-08-14 21:53:38', NULL, '2025-08-14 21:53:36', '2025-08-14 21:53:38'),
(7, 'App\\Models\\User', 1, 'auth_token', '2ed4a18cb88a420cdc1df2ca2ba40829a0087745cb51a1a356fa3bec418a401d', '[\"*\"]', '2025-08-14 22:28:42', NULL, '2025-08-14 21:56:23', '2025-08-14 22:28:42'),
(8, 'App\\Models\\User', 4, 'auth_token', '7350421db344371ecb2c5158490c0bdaf3a9339e7bafd3166a34f65985958753', '[\"*\"]', '2025-08-14 22:29:23', NULL, '2025-08-14 22:29:15', '2025-08-14 22:29:23'),
(9, 'App\\Models\\User', 5, 'auth_token', '427b2e2489905270d86d099ec77da9547f9651cded884bddd151da6bba0869a4', '[\"*\"]', '2025-08-14 22:29:58', NULL, '2025-08-14 22:29:57', '2025-08-14 22:29:58'),
(10, 'App\\Models\\User', 5, 'auth_token', '1d4bc413355515f60db71e092a4dc71acda67cb37a8ae1b872b28a7a81643a30', '[\"*\"]', '2025-08-14 22:30:13', NULL, '2025-08-14 22:30:13', '2025-08-14 22:30:13'),
(11, 'App\\Models\\User', 1, 'auth_token', 'dafaee478af5e2fc1118df485b142f0946a665eb102e46d569637396525a561c', '[\"*\"]', '2025-08-14 22:30:52', NULL, '2025-08-14 22:30:40', '2025-08-14 22:30:52'),
(12, 'App\\Models\\User', 5, 'auth_token', '9083c700fb9ef41d05979e199557e61b64d066c250a0ca1a2be030fc0f1cafff', '[\"*\"]', '2025-08-14 22:34:46', NULL, '2025-08-14 22:31:08', '2025-08-14 22:34:46'),
(13, 'App\\Models\\User', 6, 'auth_token', 'ec110c15b1b49b753fd2d55b6647af53c849d8766cadfbf24595e4c034b37468', '[\"*\"]', '2025-08-14 22:35:27', NULL, '2025-08-14 22:35:27', '2025-08-14 22:35:27'),
(14, 'App\\Models\\User', 1, 'auth_token', '0b1d91e8820054cd0db39f6bda7414c7c1d96e2949729f62a66be4ed3cdf4da3', '[\"*\"]', '2025-08-14 22:36:12', NULL, '2025-08-14 22:35:50', '2025-08-14 22:36:12'),
(15, 'App\\Models\\User', 6, 'auth_token', '15501eb94ea18a1cb0f41b8dfebf5324e5c36f0060da5e5b8066b292735dee45', '[\"*\"]', '2025-08-14 22:48:59', NULL, '2025-08-14 22:36:28', '2025-08-14 22:48:59'),
(16, 'App\\Models\\User', 6, 'auth_token', 'db438b8ae6df8a8ef99eae9e309f7b6b52d86380fcecfff103bcd1f92909acc3', '[\"*\"]', '2025-08-14 22:49:16', NULL, '2025-08-14 22:49:14', '2025-08-14 22:49:16'),
(17, 'App\\Models\\User', 1, 'auth_token', '4ec5c584a4dc981432d159af2f76dc45efff039b22b86a0699bb7bcf8fa1072a', '[\"*\"]', '2025-08-14 22:49:59', NULL, '2025-08-14 22:49:39', '2025-08-14 22:49:59'),
(18, 'App\\Models\\User', 6, 'auth_token', 'fdc2ca30aa4121a5a037a8ba9282e25b404cf853a914b3cb62c0af034cba1130', '[\"*\"]', '2025-08-14 23:17:59', NULL, '2025-08-14 22:50:16', '2025-08-14 23:17:59'),
(19, 'App\\Models\\User', 1, 'auth_token', 'e663d4709ef0e617f92088a93f632073a5d815fa25afd8f7fdd49cade838a796', '[\"*\"]', '2025-08-14 23:18:53', NULL, '2025-08-14 23:18:33', '2025-08-14 23:18:53'),
(20, 'App\\Models\\User', 6, 'auth_token', '2991f5f72429357cb01b64d893c5ff899093fed3208070ff534f059b4a4c30a5', '[\"*\"]', '2025-08-14 23:20:53', NULL, '2025-08-14 23:20:51', '2025-08-14 23:20:53'),
(21, 'App\\Models\\User', 7, 'auth_token', '1f7088a8a445cb4072b6631f5c558971f82bc6bcbbb2aa8b5466f34f69516926', '[\"*\"]', '2025-08-14 23:23:14', NULL, '2025-08-14 23:23:13', '2025-08-14 23:23:14'),
(22, 'App\\Models\\User', 1, 'auth_token', '0a12d5afa2acb78dca8947e4ce6d61043ecd25bfe480eaa2ed906bb289f18279', '[\"*\"]', '2025-08-14 23:23:42', NULL, '2025-08-14 23:23:26', '2025-08-14 23:23:42'),
(23, 'App\\Models\\User', 7, 'auth_token', 'e0732b867d5026934d15f8c427fafe2551ddb5bc279172879f8cb985ca83ed42', '[\"*\"]', '2025-08-14 23:27:44', NULL, '2025-08-14 23:24:10', '2025-08-14 23:27:44'),
(24, 'App\\Models\\User', 7, 'auth_token', 'ad05133300b0837402e1eaf6b116fab1653845f0b8808cde108b0aa00e399805', '[\"*\"]', '2025-08-14 23:28:15', NULL, '2025-08-14 23:28:13', '2025-08-14 23:28:15'),
(25, 'App\\Models\\User', 7, 'auth_token', 'd464c954fce3030daaa9f990af37163aad3151e438869c43efb188515f1ffafc', '[\"*\"]', '2025-08-14 23:33:06', NULL, '2025-08-14 23:30:35', '2025-08-14 23:33:06'),
(26, 'App\\Models\\User', 7, 'auth_token', 'ff945e5a7b2fa858bda478fca90bddb129e6063437f899548b516ea40cce4705', '[\"*\"]', '2025-08-14 23:43:41', NULL, '2025-08-14 23:33:21', '2025-08-14 23:43:41'),
(27, 'App\\Models\\User', 1, 'auth_token', 'eadfadc9541f108bfcf605428b908f2409a73a728d11665c53d4ba106e82f063', '[\"*\"]', '2025-08-14 23:46:19', NULL, '2025-08-14 23:44:39', '2025-08-14 23:46:19'),
(28, 'App\\Models\\User', 7, 'auth_token', 'b50b85fff3af5c73618617b545bda042f0fa5b69a1b63d076f9a82e2820f5a8d', '[\"*\"]', '2025-08-15 00:08:32', NULL, '2025-08-14 23:46:45', '2025-08-15 00:08:32'),
(29, 'App\\Models\\User', 3, 'auth_token', '87ae4090c401fa53e01ab81bd2a1bf596a188e6794a128f98585a5df79474680', '[\"*\"]', '2025-08-15 00:27:37', NULL, '2025-08-15 00:10:15', '2025-08-15 00:27:37'),
(30, 'App\\Models\\User', 8, 'auth_token', '375c5b6efc39fe4ee4eeea4cead811984af8f0fd057ef7200f1ef6aeb64dcd0e', '[\"*\"]', '2025-08-15 00:28:18', NULL, '2025-08-15 00:28:17', '2025-08-15 00:28:18'),
(31, 'App\\Models\\User', 8, 'auth_token', '7db00db58f82ebef8defbb12c4d5de1af6c953aa4c30ca903c30b1d533d5d077', '[\"*\"]', '2025-08-15 00:40:11', NULL, '2025-08-15 00:28:37', '2025-08-15 00:40:11'),
(32, 'App\\Models\\User', 8, 'auth_token', '24af1e9f7cb2484b00b35c52a0aec5be85628b9f6e156bfa9027904ca0b36a73', '[\"*\"]', '2025-08-15 01:53:09', NULL, '2025-08-15 00:43:08', '2025-08-15 01:53:09'),
(33, 'App\\Models\\User', 1, 'auth_token', 'e32f77537856c260d1428cf6e80e2c4b704a334b0d6fe1704b87313ce090b554', '[\"*\"]', '2025-08-15 01:54:03', NULL, '2025-08-15 01:53:22', '2025-08-15 01:54:03'),
(34, 'App\\Models\\User', 8, 'auth_token', '572cd842b15ccef90a60f7bf54235ce48323ed9e8b15631eac32a084581476ed', '[\"*\"]', '2025-08-15 02:12:03', NULL, '2025-08-15 01:55:10', '2025-08-15 02:12:03'),
(35, 'App\\Models\\User', 1, 'auth_token', '7dc22d11a967a8d6868a61be560f9df92453642be8c16800c96c7eb0f57807ee', '[\"*\"]', '2025-08-15 02:12:57', NULL, '2025-08-15 02:12:43', '2025-08-15 02:12:57'),
(36, 'App\\Models\\User', 8, 'auth_token', '9c7c5898be2bd52f6f6d67d8d00ef791bb224295b4e83df58dd6b5c3fe0e54c0', '[\"*\"]', '2025-08-15 02:21:56', NULL, '2025-08-15 02:21:33', '2025-08-15 02:21:56'),
(37, 'App\\Models\\User', 1, 'auth_token', '8f7aa09a44bf08e171221d54e4b36adf8e7eda218b81b7342277e5b149625b38', '[\"*\"]', '2025-08-15 02:22:31', NULL, '2025-08-15 02:22:11', '2025-08-15 02:22:31');

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `price` decimal(8,2) NOT NULL,
  `stock` int(11) NOT NULL,
  `department_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `reservations`
--

CREATE TABLE `reservations` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `listing_id` bigint(20) UNSIGNED NOT NULL,
  `reserved_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `status` enum('pending','approved','cancelled') NOT NULL DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sessions`
--

CREATE TABLE `sessions` (
  `id` varchar(255) NOT NULL,
  `user_id` bigint(20) UNSIGNED DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `payload` longtext NOT NULL,
  `last_activity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('student','admin','superadmin') NOT NULL DEFAULT 'student',
  `department_id` bigint(20) UNSIGNED DEFAULT NULL,
  `remember_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `email_verified_at`, `password`, `role`, `department_id`, `remember_token`, `created_at`, `updated_at`) VALUES
(1, 'Super Administrator', 'superadmin@example.com', NULL, '$2y$12$QJUIxM3.NwGp63Q0x5L8COk0aufE1yhrRLMdFrr9TjkXtC6aTisv.', 'superadmin', 1, NULL, '2025-08-14 20:40:00', '2025-08-14 20:40:00'),
(2, 'Department Admin', 'admin@example.com', NULL, '$2y$12$r5Qw1ahs5ehfpExMcgnSKu5shrGiXPJieEFGXC.oBU6zJg/KM.gCG', 'admin', 1, NULL, '2025-08-14 20:40:00', '2025-08-14 20:40:00'),
(3, 'Student User', 'student@example.com', NULL, '$2y$12$kXJphi9l/yFi6xtcEC4MvOVzuGN1Deo2iUkANxsyJCoHGfFBOtehG', 'student', 1, NULL, '2025-08-14 20:40:01', '2025-08-14 20:40:01'),
(4, 'Udd Site Admin', 'site@admin.com', NULL, '$2y$12$t/OFuunxuG8ePeKvoQvS4O26WVpuyDhgZ2p1WQseXbJ651LFZAwna', 'admin', 1, NULL, '2025-08-14 21:52:58', '2025-08-14 21:53:20'),
(5, 'site2', 'site2@admin.com', NULL, '$2y$12$x5/27YMvDMg.dTJaVNyszOWzF4Bjte.YFJb.k8KTqwowefLr2s7xG', 'admin', 1, NULL, '2025-08-14 22:29:57', '2025-08-14 22:30:50'),
(6, 'UDD SITE ADMIN', 'admin@site.com', NULL, '$2y$12$RAUk8O0gpSeF0zFeDjR1VOpI./sILIasB84g/WqppKeojPvoLyg4a', 'admin', 1, NULL, '2025-08-14 22:35:27', '2025-08-14 23:18:52'),
(7, 'test', 'test@admin.com', NULL, '$2y$12$htqEj.DfsA.t4L1B9gUt/uoTrFF6701.sJ01IWasbDhrr.EegfDg2', 'admin', 1, NULL, '2025-08-14 23:23:13', '2025-08-14 23:23:41'),
(8, 'testt', 'testt@admin.com', NULL, '$2y$12$dv8F6aQYtRRxEWmV9U7znuJWRPYoBc4TRzke36P1re8z4q9gwopfC', 'student', 6, NULL, '2025-08-15 00:28:17', '2025-08-15 00:28:17');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `cache`
--
ALTER TABLE `cache`
  ADD PRIMARY KEY (`key`);

--
-- Indexes for table `cache_locks`
--
ALTER TABLE `cache_locks`
  ADD PRIMARY KEY (`key`);

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `categories_name_unique` (`name`);

--
-- Indexes for table `departments`
--
ALTER TABLE `departments`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `departments_name_unique` (`name`);

--
-- Indexes for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`);

--
-- Indexes for table `jobs`
--
ALTER TABLE `jobs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `jobs_queue_index` (`queue`);

--
-- Indexes for table `job_batches`
--
ALTER TABLE `job_batches`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `listings`
--
ALTER TABLE `listings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `listings_department_id_foreign` (`department_id`),
  ADD KEY `listings_category_id_foreign` (`category_id`),
  ADD KEY `listings_user_id_foreign` (`user_id`);

--
-- Indexes for table `listing_size_variants`
--
ALTER TABLE `listing_size_variants`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `listing_size_variants_listing_id_size_unique` (`listing_id`,`size`);

--
-- Indexes for table `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `orders_order_number_unique` (`order_number`),
  ADD KEY `orders_user_id_foreign` (`user_id`),
  ADD KEY `orders_listing_id_foreign` (`listing_id`),
  ADD KEY `orders_department_id_foreign` (`department_id`);

--
-- Indexes for table `password_reset_tokens`
--
ALTER TABLE `password_reset_tokens`
  ADD PRIMARY KEY (`email`);

--
-- Indexes for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  ADD KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`),
  ADD KEY `personal_access_tokens_expires_at_index` (`expires_at`);

--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`id`),
  ADD KEY `products_department_id_foreign` (`department_id`);

--
-- Indexes for table `reservations`
--
ALTER TABLE `reservations`
  ADD PRIMARY KEY (`id`),
  ADD KEY `reservations_user_id_foreign` (`user_id`),
  ADD KEY `reservations_listing_id_foreign` (`listing_id`);

--
-- Indexes for table `sessions`
--
ALTER TABLE `sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `sessions_user_id_index` (`user_id`),
  ADD KEY `sessions_last_activity_index` (`last_activity`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_email_unique` (`email`),
  ADD KEY `users_role_index` (`role`),
  ADD KEY `users_department_id_index` (`department_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `categories`
--
ALTER TABLE `categories`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `departments`
--
ALTER TABLE `departments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `failed_jobs`
--
ALTER TABLE `failed_jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `jobs`
--
ALTER TABLE `jobs`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `listings`
--
ALTER TABLE `listings`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `listing_size_variants`
--
ALTER TABLE `listing_size_variants`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=36;

--
-- AUTO_INCREMENT for table `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=38;

--
-- AUTO_INCREMENT for table `products`
--
ALTER TABLE `products`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `reservations`
--
ALTER TABLE `reservations`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `listings`
--
ALTER TABLE `listings`
  ADD CONSTRAINT `listings_category_id_foreign` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `listings_department_id_foreign` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `listings_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `listing_size_variants`
--
ALTER TABLE `listing_size_variants`
  ADD CONSTRAINT `listing_size_variants_listing_id_foreign` FOREIGN KEY (`listing_id`) REFERENCES `listings` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_department_id_foreign` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `orders_listing_id_foreign` FOREIGN KEY (`listing_id`) REFERENCES `listings` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `orders_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `products`
--
ALTER TABLE `products`
  ADD CONSTRAINT `products_department_id_foreign` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `reservations`
--
ALTER TABLE `reservations`
  ADD CONSTRAINT `reservations_listing_id_foreign` FOREIGN KEY (`listing_id`) REFERENCES `listings` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reservations_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `users_department_id_foreign` FOREIGN KEY (`department_id`) REFERENCES `departments` (`id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
