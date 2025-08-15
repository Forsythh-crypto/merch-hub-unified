-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Aug 15, 2025 at 04:48 AM
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
(1, 'Clothing', NULL, NULL),
(2, 'Accessories', NULL, NULL),
(3, 'Supplies', NULL, NULL),
(4, 'Tech', NULL, NULL);

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
(1, 'School of Information Technology Education', NULL, NULL, '2025-08-12 06:03:30', '2025-08-12 06:03:30'),
(2, 'School of Teacher Education', NULL, NULL, '2025-08-12 06:03:30', '2025-08-12 06:03:30'),
(3, 'School of Criminology', NULL, 'department_logos/1755161558_scaled_1000000403.png', '2025-08-12 06:03:30', '2025-08-14 00:52:38'),
(4, 'School of Health Sciences', NULL, NULL, '2025-08-12 06:03:30', '2025-08-12 06:03:30'),
(5, 'School of Humanities', NULL, NULL, '2025-08-12 06:03:30', '2025-08-12 06:03:30'),
(6, 'School of Engineering', NULL, NULL, '2025-08-12 06:03:30', '2025-08-12 06:03:30'),
(7, 'School of International Hospitality Management', NULL, NULL, '2025-08-12 06:03:30', '2025-08-12 06:03:30'),
(15, 'School of Business and Accountancy', 'SBA', NULL, '2025-08-14 01:01:22', '2025-08-14 01:40:13');

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
(1, 'UDD Hoodie', 'Limited Edition', NULL, 1, 1, 7, 750.00, 'approved', 5, 'XL', '2025-08-13 07:14:11', '2025-08-13 08:01:18'),
(2, 'test', 'test', NULL, 1, 3, 7, 100.00, 'approved', 12, NULL, '2025-08-13 20:41:06', '2025-08-13 20:41:17'),
(3, 'haha', 'ss', NULL, 3, 3, 6, 150.00, 'approved', 5, NULL, '2025-08-14 03:46:34', '2025-08-14 04:21:23'),
(4, 'shs', 'hd', 'listings/5NCA8xphnqalfURO7BBDZ4QQ6jwL310GqiGvnJsn.png', 3, 2, 6, 150.00, 'approved', 1, NULL, '2025-08-14 03:58:00', '2025-08-14 04:21:17'),
(5, 'haha', 'ww', 'listings/oRFIlNPOY4YB8ONAFWBIRl5rzp3Hu8oZ2AaeFBpA.jpg', 4, 2, 6, 150.00, 'approved', 15, NULL, '2025-08-14 04:02:36', '2025-08-14 04:21:11'),
(6, 'ahah', 'shs', 'listings/tlHsJ4Vt8b7yXmL4K0egq7dtVtJvDTPFUf1hcIRj.jpg', 6, 3, 6, 150.00, 'approved', 4, NULL, '2025-08-14 04:09:38', '2025-08-14 04:21:04'),
(7, 'ss', 'ss', NULL, 15, 1, 6, 15.00, 'approved', 1, 'S', '2025-08-14 05:12:03', '2025-08-14 05:12:03');

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
(8, '2025_08_12_100910_create_orders_table', 1),
(9, '2025_08_12_105758_create_listings_table', 1),
(10, '2025_08_12_105943_create_reservations_table', 1),
(11, '2025_08_13_123817_add_status_and_stock_to_listings_table', 2),
(12, '2025_08_14_053924_add_description_to_departments_table', 3),
(13, '2025_08_15_000000_add_logo_to_departments_table', 4);

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `product_id` bigint(20) UNSIGNED NOT NULL,
  `quantity` int(11) NOT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'pending',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
(1, 'App\\Models\\User', 1, 'auth_token', 'a014a334ef7dc749d4389e6a4d1a855deed590c5386f5407ff13de470939b3cc', '[\"*\"]', NULL, NULL, '2025-08-12 06:46:49', '2025-08-12 06:46:49'),
(2, 'App\\Models\\User', 1, 'auth_token', '0ed03b0d23628f0238f31eda95fea93a05cf4e3700b872c8aa738b75b8c9a76d', '[\"*\"]', NULL, NULL, '2025-08-12 06:48:59', '2025-08-12 06:48:59'),
(3, 'App\\Models\\User', 2, 'auth_token', '90bd737450f09c500256ec1aff241e7d411f3364229dd6737d90c47284b97878', '[\"*\"]', NULL, NULL, '2025-08-12 07:30:49', '2025-08-12 07:30:49'),
(4, 'App\\Models\\User', 3, 'auth_token', '6008e232ea6dda72f8f90fefdbd5d0a82bcdebb323e17ed8ce0414fb11e08779', '[\"*\"]', NULL, NULL, '2025-08-12 07:39:24', '2025-08-12 07:39:24'),
(5, 'App\\Models\\User', 3, 'auth_token', 'ddd2998eb39160dcba720b8375b4f333af80990502f64dd8002f0dbb7b427ca1', '[\"*\"]', NULL, NULL, '2025-08-12 07:40:29', '2025-08-12 07:40:29'),
(6, 'App\\Models\\User', 4, 'auth_token', 'df13d600605a3386e4dba61d7d1c565ed73eea2f782126686c44e4286368fb46', '[\"*\"]', '2025-08-12 07:45:04', NULL, '2025-08-12 07:45:03', '2025-08-12 07:45:04'),
(7, 'App\\Models\\User', 4, 'auth_token', 'dc81bfcd1f6202d73ccb3b33985d4f5fd6306fca5967bcfd4adcab14c6c8e190', '[\"*\"]', NULL, NULL, '2025-08-12 07:46:10', '2025-08-12 07:46:10'),
(8, 'App\\Models\\User', 4, 'auth_token', '265a8d56ffd23a68f66e74fee5ec5380df6121377622aa469c5bf9c6d9f0c22e', '[\"*\"]', NULL, NULL, '2025-08-12 07:46:28', '2025-08-12 07:46:28'),
(9, 'App\\Models\\User', 4, 'auth_token', 'e02908bb774afa65449b8387f0076203a3167f2bd049908acc1686e365ea2765', '[\"*\"]', NULL, NULL, '2025-08-12 08:10:05', '2025-08-12 08:10:05'),
(10, 'App\\Models\\User', 4, 'auth_token', 'e7d192f88c714d379a99bbe078a232b0589bdb404f27caf9cbd829bfbf679e7a', '[\"*\"]', NULL, NULL, '2025-08-12 08:20:23', '2025-08-12 08:20:23'),
(11, 'App\\Models\\User', 5, 'auth_token', '7aed2229dfcd28e63919104a5f18ab1c73fe8cf7505aa58eee0f43014bd06b48', '[\"*\"]', NULL, NULL, '2025-08-12 08:28:34', '2025-08-12 08:28:34'),
(12, 'App\\Models\\User', 4, 'auth_token', '1e7ea8d40a813f5f41f5f5bbdd4bd447db7735e7c16b135a014cfef850274ba1', '[\"*\"]', NULL, NULL, '2025-08-13 03:56:53', '2025-08-13 03:56:53'),
(13, 'App\\Models\\User', 4, 'auth_token', '026996b0a777f07e4e09e3e98ca73551d39a5e309fa826d382586fad8dc1c20b', '[\"*\"]', NULL, NULL, '2025-08-13 03:59:58', '2025-08-13 03:59:58'),
(14, 'App\\Models\\User', 4, 'auth_token', '293dc2fb39997b7af6e3b29a34a3c6f2f47f0ec04be57b0634eb2d0efdb732cc', '[\"*\"]', NULL, NULL, '2025-08-13 04:04:19', '2025-08-13 04:04:19'),
(15, 'App\\Models\\User', 6, 'auth_token', '083f735b27dac4f98f0ceecf0fe3def4137461b292522541d2c6330e4adb000a', '[\"*\"]', NULL, NULL, '2025-08-13 04:21:34', '2025-08-13 04:21:34'),
(16, 'App\\Models\\User', 6, 'auth_token', 'f26f4b2a233f199630689f3eb4d5e5f80ba67bf077ed229cc6ed10b229351f9a', '[\"*\"]', '2025-08-13 04:45:16', NULL, '2025-08-13 04:34:32', '2025-08-13 04:45:16'),
(17, 'App\\Models\\User', 4, 'auth_token', '7d3cded1acc224c6b9b585416efe0f2e632ed7d61d16c8e4bc20341cae2bc778', '[\"*\"]', '2025-08-13 04:51:16', NULL, '2025-08-13 04:46:57', '2025-08-13 04:51:16'),
(18, 'App\\Models\\User', 10, 'auth_token', 'ebad2fd22825c7edd1416bebc4dc1fb502d56ae77c24805044135a5bb34df3cf', '[\"*\"]', '2025-08-13 04:51:36', NULL, '2025-08-13 04:51:35', '2025-08-13 04:51:36'),
(19, 'App\\Models\\User', 6, 'auth_token', '879af6224df4911ef132b4203993fe3ea0bb93b9e2d8d579cdb65a1cc7a7d9b4', '[\"*\"]', '2025-08-13 04:58:52', NULL, '2025-08-13 04:51:59', '2025-08-13 04:58:52'),
(20, 'App\\Models\\User', 6, 'auth_token', '053ef198c003b18aeb1df725ccb5179c1ee5c40f0ccff7ac4f712e28cbfa1e46', '[\"*\"]', '2025-08-13 05:02:21', NULL, '2025-08-13 05:01:12', '2025-08-13 05:02:21'),
(21, 'App\\Models\\User', 6, 'auth_token', 'dfcc10afe75ab4072a9ceb19283f7ef05a409b6d85b8f6cb3e56ee3f90afd87e', '[\"*\"]', '2025-08-13 05:08:13', NULL, '2025-08-13 05:04:31', '2025-08-13 05:08:13'),
(22, 'App\\Models\\User', 7, 'auth_token', '7b2f31b8252caee52eb5b8d69bba1acff0336dd911e5c18019dec4a24fbffcae', '[\"*\"]', '2025-08-13 05:08:48', NULL, '2025-08-13 05:08:35', '2025-08-13 05:08:48'),
(23, 'App\\Models\\User', 6, 'auth_token', 'aa10b3d4e718e3a8bf140df150560785f28080b93974e59105e25714846afcbb', '[\"*\"]', '2025-08-13 05:16:22', NULL, '2025-08-13 05:12:38', '2025-08-13 05:16:22'),
(24, 'App\\Models\\User', 6, 'auth_token', 'e418cc369551f993bcf9d06e18e17b8b2e18349c19ae7e526fef038d97e3bd20', '[\"*\"]', '2025-08-13 05:33:05', NULL, '2025-08-13 05:17:46', '2025-08-13 05:33:05'),
(25, 'App\\Models\\User', 6, 'auth_token', 'ca8fe90fdf9f5c15f491488a526e67df022ece45eac76913457f0e6f28eea033', '[\"*\"]', '2025-08-13 06:13:28', NULL, '2025-08-13 05:38:43', '2025-08-13 06:13:28'),
(26, 'App\\Models\\User', 6, 'auth_token', 'dc1beac41ad894b93860146c9c781a3c04c80f2e2bf61b86998bf089995a42da', '[\"*\"]', '2025-08-13 06:21:47', NULL, '2025-08-13 06:21:32', '2025-08-13 06:21:47'),
(27, 'App\\Models\\User', 12, 'auth_token', 'b9c7ecd917f4053fd5210a62ef56d06ccd29a46c1ba579f6215ee3eefc0217b1', '[\"*\"]', '2025-08-13 06:53:04', NULL, '2025-08-13 06:52:57', '2025-08-13 06:53:04'),
(28, 'App\\Models\\User', 6, 'auth_token', 'eb45d043de9f00a121285fb4cd2def1745749338d1944da130aadeeee3d0402e', '[\"*\"]', '2025-08-13 07:02:19', NULL, '2025-08-13 07:02:17', '2025-08-13 07:02:19'),
(29, 'App\\Models\\User', 6, 'auth_token', 'b575db505e50c829b0f9a1fde0ae0112a1c59f82785b86faefc3cfbe8a3a20dd', '[\"*\"]', '2025-08-13 07:08:37', NULL, '2025-08-13 07:05:13', '2025-08-13 07:08:37'),
(30, 'App\\Models\\User', 7, 'auth_token', 'e02214a16a8bd5fc0abab8f28878166141d04009a1fa574f95c6f2cc23001b92', '[\"*\"]', '2025-08-13 07:14:11', NULL, '2025-08-13 07:10:00', '2025-08-13 07:14:11'),
(31, 'App\\Models\\User', 6, 'auth_token', '0ac6164b7ba6ce92fab5493b6de2c1cb258b818b59fbf1c2229feda9328643ed', '[\"*\"]', '2025-08-13 07:15:04', NULL, '2025-08-13 07:15:02', '2025-08-13 07:15:04'),
(32, 'App\\Models\\User', 6, 'auth_token', '239a9d5c1bbf40a4d036a6875082cb6a5d8f2b067f235dbd3fcd36fe00ef0b85', '[\"*\"]', '2025-08-13 07:16:15', NULL, '2025-08-13 07:16:13', '2025-08-13 07:16:15'),
(33, 'App\\Models\\User', 4, 'auth_token', '6e3c125c0381919f7844a146167199f2d39a99f84bef5796b44d03c1c6ba7b73', '[\"*\"]', '2025-08-13 07:16:51', NULL, '2025-08-13 07:16:34', '2025-08-13 07:16:51'),
(34, 'App\\Models\\User', 6, 'auth_token', 'a026462d409bc7f4c5b306974d3b71e56852c2dcaba3b27ca161faa93c1ae501', '[\"*\"]', '2025-08-13 07:18:08', NULL, '2025-08-13 07:17:15', '2025-08-13 07:18:08'),
(35, 'App\\Models\\User', 4, 'auth_token', 'deea282f9366bcc63d5ab3902af9e8c22b88e7b6278730c24227de7af2f5da32', '[\"*\"]', '2025-08-13 07:18:50', NULL, '2025-08-13 07:18:24', '2025-08-13 07:18:50'),
(36, 'App\\Models\\User', 6, 'auth_token', 'ed86d40bb036f6499f8494e64d9d78b76ced6007ff11365891a8515c2bf5ed9e', '[\"*\"]', '2025-08-13 07:23:32', NULL, '2025-08-13 07:23:29', '2025-08-13 07:23:32'),
(37, 'App\\Models\\User', 7, 'auth_token', '0661bbd754063be285b1407401719def23cc51274d436afe2a86b743c7508f6c', '[\"*\"]', '2025-08-13 07:24:32', NULL, '2025-08-13 07:24:27', '2025-08-13 07:24:32'),
(38, 'App\\Models\\User', 6, 'auth_token', '4f57c1dbde3ce42ed660fb43c897e7c344cf394d1889b868f93f2674882d91eb', '[\"*\"]', '2025-08-13 07:35:11', NULL, '2025-08-13 07:28:19', '2025-08-13 07:35:11'),
(39, 'App\\Models\\User', 6, 'auth_token', '80f76b9a59ea6c826ba9565ace03a29443f7f34c0195793b53b21135d6409e47', '[\"*\"]', '2025-08-13 07:37:54', NULL, '2025-08-13 07:35:25', '2025-08-13 07:37:54'),
(40, 'App\\Models\\User', 6, 'auth_token', '64bda7badeed8598d9b3c6181d8459e251c0fb99c127ba37ff835b32323de89b', '[\"*\"]', '2025-08-13 07:39:54', NULL, '2025-08-13 07:39:51', '2025-08-13 07:39:54'),
(41, 'App\\Models\\User', 7, 'auth_token', '77dd4d16e522984089a93c041d2743eddb966cdc6a31bf433004efb2c81c12fb', '[\"*\"]', '2025-08-13 07:40:34', NULL, '2025-08-13 07:40:26', '2025-08-13 07:40:34'),
(42, 'App\\Models\\User', 6, 'auth_token', 'c13155dc0d644f90c40fb1deb6769256356320737218c2ad98897bf075094330', '[\"*\"]', '2025-08-13 08:01:18', NULL, '2025-08-13 07:45:21', '2025-08-13 08:01:18'),
(43, 'App\\Models\\User', 6, 'auth_token', '6a29256fb5c2267bd877dd0c038ed47d0df0b16af81e8032c825f4bd982d80e5', '[\"*\"]', NULL, NULL, '2025-08-13 09:54:05', '2025-08-13 09:54:05'),
(44, 'App\\Models\\User', 6, 'auth_token', '2ca5e8b309b26868b3644e5948acd525de022e6f103e4214e23b4402a10489c0', '[\"*\"]', NULL, NULL, '2025-08-13 09:54:19', '2025-08-13 09:54:19'),
(45, 'App\\Models\\User', 6, 'auth_token', 'c6c93f67db859118aac516b189359ed0f687e2ade30ef46dff4af6654e58425d', '[\"*\"]', '2025-08-13 09:56:43', NULL, '2025-08-13 09:54:27', '2025-08-13 09:56:43'),
(46, 'App\\Models\\User', 7, 'auth_token', '062cb2eee9ca1ee62d68fb19f5275c321439559856e64115477543f8c7939b09', '[\"*\"]', NULL, NULL, '2025-08-13 09:57:06', '2025-08-13 09:57:06'),
(47, 'App\\Models\\User', 7, 'auth_token', '5e513a62a9437d281084f28d6e72cd600a4aef888eec5e5c7243e0f88fb9e4a1', '[\"*\"]', '2025-08-13 10:00:20', NULL, '2025-08-13 09:57:14', '2025-08-13 10:00:20'),
(48, 'App\\Models\\User', 4, 'auth_token', '65bc6ecac89c1b48254c472db5e574a299d6cd500011ed2ccd66361819067694', '[\"*\"]', '2025-08-13 18:27:59', NULL, '2025-08-13 18:18:59', '2025-08-13 18:27:59'),
(49, 'App\\Models\\User', 6, 'auth_token', 'a26b4683d9ca5c5e39b4034451f41e8a2b570fcde5c53c2f35a55da30030a8a4', '[\"*\"]', '2025-08-13 18:29:26', NULL, '2025-08-13 18:29:24', '2025-08-13 18:29:26'),
(50, 'App\\Models\\User', 4, 'auth_token', '3e12a05331697e9e12ec31a0bedee610b432810248e71fa7ac39523676c0b23d', '[\"*\"]', '2025-08-13 18:38:10', NULL, '2025-08-13 18:30:58', '2025-08-13 18:38:10'),
(51, 'App\\Models\\User', 13, 'auth_token', 'a1284ce63e07e5cba2190ec0ba45934abccfc60d06641faf38f21a2882044f30', '[\"*\"]', '2025-08-13 18:42:50', NULL, '2025-08-13 18:42:49', '2025-08-13 18:42:50'),
(52, 'App\\Models\\User', 13, 'auth_token', '279f05b8278760f2ac5b3cea47fdea4de7173eeeb97207c660ac341cad4f2416', '[\"*\"]', '2025-08-13 18:43:05', NULL, '2025-08-13 18:43:04', '2025-08-13 18:43:05'),
(53, 'App\\Models\\User', 6, 'auth_token', '1f7de9f6102629ab1f529a494436c4201718940c54a9742c66244ac3338519a6', '[\"*\"]', '2025-08-13 18:43:42', NULL, '2025-08-13 18:43:40', '2025-08-13 18:43:42'),
(54, 'App\\Models\\User', 6, 'auth_token', '43a9e4be27082b7b20b865d62600dc8eb64b038d9f2ce9eddae6846fb37df252', '[\"*\"]', NULL, NULL, '2025-08-13 18:58:56', '2025-08-13 18:58:56'),
(55, 'App\\Models\\User', 6, 'auth_token', 'a532d263cbbfe4238e99aa3c565ac5cbaebaffdaaff50c2146c3f5434aaa5705', '[\"*\"]', '2025-08-14 02:50:24', NULL, '2025-08-13 19:06:32', '2025-08-14 02:50:24'),
(56, 'App\\Models\\User', 6, 'auth_token', '72e83ef71bdeb909a1b606fd1aca23e8d0e0f41725f55683a9fc817fbbe2a4d2', '[\"*\"]', '2025-08-13 19:08:02', NULL, '2025-08-13 19:08:00', '2025-08-13 19:08:02'),
(57, 'App\\Models\\User', 7, 'auth_token', '48243d9d20bbe76e11ce7c1f2631ddc1c385fd2375a4e80bf37d4303aaa06dc9', '[\"*\"]', '2025-08-13 19:08:29', NULL, '2025-08-13 19:08:25', '2025-08-13 19:08:29'),
(58, 'App\\Models\\User', 4, 'auth_token', '5127a19d0fbe1711634e08488a0127fe85c6235c3fc6cd9d1588e4f1a11d5e0b', '[\"*\"]', '2025-08-13 19:18:00', NULL, '2025-08-13 19:08:42', '2025-08-13 19:18:00'),
(59, 'App\\Models\\User', 6, 'auth_token', 'cb0ce2cc5d2bd0d39e1f69efd25d07965f574b9db0c4132f43a0f230460967c0', '[\"*\"]', '2025-08-13 19:42:13', NULL, '2025-08-13 19:19:16', '2025-08-13 19:42:13'),
(60, 'App\\Models\\User', 6, 'auth_token', '74329767fafe984a67050255038f21d332a0f1f255da09a5a1a087ad173d5a34', '[\"*\"]', '2025-08-13 20:11:58', NULL, '2025-08-13 20:02:59', '2025-08-13 20:11:58'),
(61, 'App\\Models\\User', 6, 'auth_token', 'af375a7266539d06bd6bdd114698324594d935f069a4bf545828d9a39e9ebfd4', '[\"*\"]', '2025-08-13 20:19:04', NULL, '2025-08-13 20:12:52', '2025-08-13 20:19:04'),
(62, 'App\\Models\\User', 7, 'auth_token', '0f028f0a8a9e1795aa31c78d908fd4467d88f8cddac60fd642da39e1f2aa2d4e', '[\"*\"]', '2025-08-13 20:25:58', NULL, '2025-08-13 20:19:47', '2025-08-13 20:25:58'),
(63, 'App\\Models\\User', 7, 'auth_token', 'a9f0f2b1f3944b8948b76c8f37b8d3654b0890bcead50296ae81af2eefc06377', '[\"*\"]', '2025-08-13 20:26:54', NULL, '2025-08-13 20:26:49', '2025-08-13 20:26:54'),
(64, 'App\\Models\\User', 6, 'auth_token', 'fc23227c6fa9d2d60b624a056c4e46cf2d59f4d2214cbd33d8bb9cb61cddcf52', '[\"*\"]', '2025-08-13 20:27:22', NULL, '2025-08-13 20:27:20', '2025-08-13 20:27:22'),
(65, 'App\\Models\\User', 6, 'auth_token', '1d0200e2b532d1f93ba05593b8c4ec9f775104f92ecace5891a6d8325d81d87e', '[\"*\"]', '2025-08-13 20:36:37', NULL, '2025-08-13 20:27:42', '2025-08-13 20:36:37'),
(66, 'App\\Models\\User', 6, 'auth_token', 'e81c639a0cb917274b63c8951a37aba1459df7fd7bd5b41c1906792e7c82ff17', '[\"*\"]', '2025-08-13 20:39:32', NULL, '2025-08-13 20:38:02', '2025-08-13 20:39:32'),
(67, 'App\\Models\\User', 7, 'auth_token', '4082a21282ab9e2a6d22598d5a01211043e51301703bb6d1af386047cbca6d19', '[\"*\"]', '2025-08-13 20:41:18', NULL, '2025-08-13 20:40:44', '2025-08-13 20:41:18'),
(68, 'App\\Models\\User', 6, 'auth_token', '5ebbc97193b8dcec05864ca4d92ac35364e31a50abf91cc460b066c4569c9045', '[\"*\"]', '2025-08-13 20:41:45', NULL, '2025-08-13 20:41:35', '2025-08-13 20:41:45'),
(69, 'App\\Models\\User', 6, 'auth_token', 'f1cd43ff6379b53c6664f2f0c2f0338ad861691c0b54aef8cd671a3fbbc84511', '[\"*\"]', '2025-08-13 20:46:09', NULL, '2025-08-13 20:43:06', '2025-08-13 20:46:09'),
(70, 'App\\Models\\User', 6, 'auth_token', '09cd0180dea9c70ac996c13730e84a72405453cb6cd50df22fe4f386cb0020c5', '[\"*\"]', '2025-08-13 20:47:26', NULL, '2025-08-13 20:47:24', '2025-08-13 20:47:26'),
(71, 'App\\Models\\User', 6, 'auth_token', '65720e8a924715f57506662da546a4e73d6de09ceff42c8a90ee503e09c9340f', '[\"*\"]', '2025-08-13 20:48:17', NULL, '2025-08-13 20:48:14', '2025-08-13 20:48:17'),
(72, 'App\\Models\\User', 6, 'auth_token', 'b1a9058b923e0e96c5ed5f036bbb5c31df9e8b558f3d2ea003219b08c3e03e87', '[\"*\"]', '2025-08-13 21:01:25', NULL, '2025-08-13 20:50:55', '2025-08-13 21:01:25'),
(73, 'App\\Models\\User', 6, 'auth_token', '96972fafb261ba83b8308a9fe75198f043b2ba78367c2874d67b65b5d7c81970', '[\"*\"]', NULL, NULL, '2025-08-13 21:02:52', '2025-08-13 21:02:52'),
(74, 'App\\Models\\User', 6, 'auth_token', '71366c2cbccb721d1dc47049e2fd7f3c3d6af89b71b8bc8aa3007ad7ccf1cdb7', '[\"*\"]', '2025-08-13 21:05:14', NULL, '2025-08-13 21:03:25', '2025-08-13 21:05:14'),
(75, 'App\\Models\\User', 6, 'auth_token', 'a208d444917864d87b8582a50695cca9eac8c5c3f3a4372d66e286e7f47b53db', '[\"*\"]', '2025-08-13 21:09:07', NULL, '2025-08-13 21:05:33', '2025-08-13 21:09:07'),
(76, 'App\\Models\\User', 6, 'auth_token', '233e23a1cde76b71fdd07ce6dbdb180b9abdd62f5b0565328af1e4c0bc752d87', '[\"*\"]', '2025-08-13 21:10:29', NULL, '2025-08-13 21:09:30', '2025-08-13 21:10:29'),
(77, 'App\\Models\\User', 6, 'auth_token', '25ffcdda2d2c3e0a212249634e25aee8cb365d15bd13cd49d4bd4ed693f926b5', '[\"*\"]', NULL, NULL, '2025-08-13 21:12:36', '2025-08-13 21:12:36'),
(78, 'App\\Models\\User', 6, 'auth_token', 'da091b3f8ee28c76ebc78faf2fc6730f23bff0eae8e6b4058d100574a80e9654', '[\"*\"]', NULL, NULL, '2025-08-13 21:15:44', '2025-08-13 21:15:44'),
(79, 'App\\Models\\User', 6, 'auth_token', '8f518aa6d22e27edea1d2f98db51cb596191f54ba756a2cbfa15d61183dc0733', '[\"*\"]', '2025-08-13 21:22:22', NULL, '2025-08-13 21:16:35', '2025-08-13 21:22:22'),
(80, 'App\\Models\\User', 6, 'auth_token', '6f3f7cd178fb07748e0936765ea966897cee82a92aa5cb01d21797108c3cf7de', '[\"*\"]', '2025-08-13 21:22:53', NULL, '2025-08-13 21:22:48', '2025-08-13 21:22:53'),
(81, 'App\\Models\\User', 6, 'auth_token', '51dabfec726c14bfe4a8f4c799ce4de628716e68558bb085bd54e2af2233f04d', '[\"*\"]', '2025-08-13 21:23:54', NULL, '2025-08-13 21:23:52', '2025-08-13 21:23:54'),
(82, 'App\\Models\\User', 6, 'auth_token', '0705771de8758c26f29cd55261ae9ccc0758ae398b5c4562104c23eaa34c9650', '[\"*\"]', '2025-08-13 21:24:44', NULL, '2025-08-13 21:24:43', '2025-08-13 21:24:44'),
(83, 'App\\Models\\User', 6, 'auth_token', '212fb9d5622a57b30844329860334227ac067b0976dec2ac4d664e31cab3bdad', '[\"*\"]', '2025-08-13 21:27:53', NULL, '2025-08-13 21:27:51', '2025-08-13 21:27:53'),
(84, 'App\\Models\\User', 6, 'auth_token', '71e96ad4fb19ae85aa397987fcb66b4b591fa71671513b90535dc4be5d68e218', '[\"*\"]', '2025-08-13 21:47:20', NULL, '2025-08-13 21:28:55', '2025-08-13 21:47:20'),
(85, 'App\\Models\\User', 6, 'auth_token', '79af21b9b7bc735b05c44e5d40a6b6af635d48f192f32b192aa9b3df4295eceb', '[\"*\"]', '2025-08-13 22:12:16', NULL, '2025-08-13 22:01:47', '2025-08-13 22:12:16'),
(86, 'App\\Models\\User', 6, 'auth_token', '13a909651c0f977ffee990a7d25dd595bf79104e42f5bd73a4d6e7c9afd5f5cf', '[\"*\"]', '2025-08-13 22:16:04', NULL, '2025-08-13 22:12:29', '2025-08-13 22:16:04'),
(87, 'App\\Models\\User', 6, 'auth_token', 'c082ddb591fd5045f7ee1575bff7561e19af755445c678596d59cc94dccd1246', '[\"*\"]', '2025-08-13 22:25:18', NULL, '2025-08-13 22:16:23', '2025-08-13 22:25:18'),
(88, 'App\\Models\\User', 6, 'auth_token', 'b080b2a47ac51cd8f3f631024370db5e0c36e0f6473b2060e81615a89e355caa', '[\"*\"]', '2025-08-13 22:51:05', NULL, '2025-08-13 22:25:35', '2025-08-13 22:51:05'),
(89, 'App\\Models\\User', 6, 'auth_token', 'aea779f81847e8f5a8191646a5e9124f979350a4696307d3a31aafb7a36cb21a', '[\"*\"]', '2025-08-14 00:45:12', NULL, '2025-08-14 00:25:37', '2025-08-14 00:45:12'),
(90, 'App\\Models\\User', 6, 'auth_token', '672d45c7b0c569a45902b096dd25dc6a3a98c1b0828cad4d65da62f93cfc5c9a', '[\"*\"]', '2025-08-14 01:14:35', NULL, '2025-08-14 01:02:57', '2025-08-14 01:14:35'),
(91, 'App\\Models\\User', 7, 'auth_token', '643046b1f657a9dd713b973a6f09bc5342e8be03c7f9e0dfa7a70d5131372a90', '[\"*\"]', '2025-08-14 03:10:51', NULL, '2025-08-14 02:50:50', '2025-08-14 03:10:51'),
(92, 'App\\Models\\User', 7, 'auth_token', 'a46ad404fe913ccd305172e1f9de5a265999ba9029316e8436d9ef4e5ec3b829', '[\"*\"]', '2025-08-14 03:12:07', NULL, '2025-08-14 03:11:30', '2025-08-14 03:12:07'),
(93, 'App\\Models\\User', 6, 'auth_token', 'f3f526b892cfc01e16fe0a088d0c8d67b2ccbd2fc0e6ac3bdf5c017cca33280e', '[\"*\"]', '2025-08-14 03:15:00', NULL, '2025-08-14 03:12:30', '2025-08-14 03:15:00'),
(94, 'App\\Models\\User', 7, 'auth_token', 'abb72f0f5cd547059170d91f9628a4c4817362a8cedac22c83264759b071f7dc', '[\"*\"]', '2025-08-14 03:15:17', NULL, '2025-08-14 03:15:16', '2025-08-14 03:15:17'),
(95, 'App\\Models\\User', 6, 'auth_token', 'cf4bb5a90eaa16b1f2383a129809442a4c9b540bf353c4726d68902c99c80167', '[\"*\"]', '2025-08-14 03:27:19', NULL, '2025-08-14 03:15:35', '2025-08-14 03:27:19'),
(96, 'App\\Models\\User', 4, 'auth_token', 'b73d612dd6e34fab413f2a79e84d3d8bdf7abc271b0995acf323cb2e9c659885', '[\"*\"]', '2025-08-14 03:28:02', NULL, '2025-08-14 03:28:01', '2025-08-14 03:28:02'),
(97, 'App\\Models\\User', 7, 'auth_token', '0b34f3f3f7a0f84d5b1985b7c5d2d9c62ab008884890a973359076d23da50d01', '[\"*\"]', '2025-08-14 03:39:34', NULL, '2025-08-14 03:29:15', '2025-08-14 03:39:34'),
(98, 'App\\Models\\User', 6, 'auth_token', '6bef3f19a8e4cac85a60fbb9a26c7172468b315add9514e56e4584eb1214a68b', '[\"*\"]', '2025-08-14 04:09:39', NULL, '2025-08-14 03:40:14', '2025-08-14 04:09:39'),
(99, 'App\\Models\\User', 4, 'auth_token', '9c26dd7c3471914e35f4275f5a90260f2f8d843da0fd436c226ac198e0454cf2', '[\"*\"]', '2025-08-14 04:14:11', NULL, '2025-08-14 04:11:08', '2025-08-14 04:14:11'),
(100, 'App\\Models\\User', 6, 'auth_token', '59efde9afe3db8762f9b115220e71db6636ae5493608ceb5f2ca95674579ced1', '[\"*\"]', '2025-08-14 04:21:23', NULL, '2025-08-14 04:16:53', '2025-08-14 04:21:23'),
(101, 'App\\Models\\User', 4, 'auth_token', 'd226435406c37ca3b7b21e04e444938409072643e2cb5d9552685d9448efb7cc', '[\"*\"]', '2025-08-14 04:44:29', NULL, '2025-08-14 04:21:40', '2025-08-14 04:44:29'),
(102, 'App\\Models\\User', 6, 'auth_token', '03c3b5764789c59b70739d31d8ea83b15a3dc041b2270f5f84494621f9eb1fd4', '[\"*\"]', '2025-08-14 05:21:51', NULL, '2025-08-14 04:44:51', '2025-08-14 05:21:51'),
(103, 'App\\Models\\User', 4, 'auth_token', '2341df8f9da135543a818257a4ac9dfeb88cfcf637c1de0bf3a13e82c232aab4', '[\"*\"]', '2025-08-14 05:49:39', NULL, '2025-08-14 05:41:43', '2025-08-14 05:49:39');

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
(1, 'Test User', 'test@example.com', NULL, '$2y$12$FuoKZvKXwysRbreq73huFuFV4VOOfM5KCTTvLVHULvwtBxnNknCEO', 'admin', 1, NULL, '2025-08-12 06:16:09', '2025-08-12 06:16:09'),
(2, 'Michael', 'michael@gmail.com', NULL, '$2y$12$crR0GFcTlmG53s/Hb0A2l.ZWpLQfwvJJsXlq4oNNyV3UdZLsVlMBG', 'admin', NULL, NULL, '2025-08-12 07:30:23', '2025-08-13 21:29:15'),
(3, 'John', 'john@gmail.com', NULL, '$2y$12$A7o9670BDemdLFyARyUBbujloE/MRzvmQKETmi1/5Fqj.E8H8sQk.', 'student', NULL, NULL, '2025-08-12 07:39:24', '2025-08-12 07:39:24'),
(4, 'Jan', 'jan@gmail.com', NULL, '$2y$12$AfK.SLpxZkMPZB7SgrPqyeoMRw6/aolu3CORpZZnice/us7G9VtKu', 'student', NULL, NULL, '2025-08-12 07:45:03', '2025-08-12 07:45:03'),
(5, 'hehe', 'hehe@haha.com', NULL, '$2y$12$9bnBpfXmez4P7DOfH.e1Je4OWtuaKp2qGUWjxL5bWRB3h8k.0PtcK', 'admin', NULL, NULL, '2025-08-12 08:28:34', '2025-08-14 01:41:35'),
(6, 'Super Administrator', 'superadmin@example.com', NULL, '$2y$12$V8AvJcaDizWCj4IFFlrNjeZqx3gYFhwPRqbRmMLOPCwJ3wLGxZrY.', 'superadmin', 1, NULL, '2025-08-13 04:20:03', '2025-08-13 04:20:03'),
(7, 'Department Admin', 'admin@example.com', NULL, '$2y$12$//bV0RkhBNgxIM4mlaiICuCoh8YnQOL1uPsVi4fytoq9vzEWKD8UC', 'admin', 1, NULL, '2025-08-13 04:20:03', '2025-08-13 04:20:03'),
(8, 'Student User', 'student@example.com', NULL, '$2y$12$Oe27Co3Zf2W8t.O5h/64vuxRiWY.CsUa2X11m/Xr90zWmWm46CmPW', 'student', 1, NULL, '2025-08-13 04:20:04', '2025-08-13 04:20:04'),
(9, 'My Super Admin', 'mysuperadmin@example.com', NULL, '$2y$12$AoGEob1m.GBa512vwPVOKuw4VVBbuFopT8G0/ZUWjoySh/4E7G0hC', 'superadmin', 1, NULL, '2025-08-13 04:20:42', '2025-08-13 04:20:42'),
(10, 'Mike', 'haha@gmail.com', NULL, '$2y$12$WaveGr0K/ErjqACQJgvnCuGEBztUabzxPaG3EeDN6eT7R6QDHqKNu', 'admin', 5, NULL, '2025-08-13 04:51:35', '2025-08-13 07:37:52'),
(11, 'Test SuperAdmin', 'test@admin.com', NULL, '$2y$12$TF2xHyoIu9M4LTao5pDUDeG8EPD/Z0ovT3pQ6H3yAkFscDYNVkaim', 'superadmin', 1, NULL, '2025-08-13 04:55:46', '2025-08-13 04:55:46'),
(12, 'da', 'dasd@gmail.com', NULL, '$2y$12$X4UzlQGLa/P.qv09xqTm9uXWOjTcpS7NKpuTIReOXfrugfPGzJRDi', 'student', 3, NULL, '2025-08-13 06:52:57', '2025-08-13 06:52:57'),
(13, 'Arvin Siapno', 'arvin@gmail.com', NULL, '$2y$12$fEd4xPIuW3mwsmBc1F.M1OhOzhjYEFsGBjWY6Cau0ojJZDNlQ3dBC', 'student', 1, NULL, '2025-08-13 18:42:49', '2025-08-13 18:42:49');

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
-- Indexes for table `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`id`),
  ADD KEY `orders_user_id_foreign` (`user_id`),
  ADD KEY `orders_product_id_foreign` (`product_id`);

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `departments`
--
ALTER TABLE `departments`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=16;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `migrations`
--
ALTER TABLE `migrations`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `personal_access_tokens`
--
ALTER TABLE `personal_access_tokens`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=104;

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
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

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
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
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
