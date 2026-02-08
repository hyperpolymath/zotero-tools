<?php
/**
 * WordPress stubs for PHPStan analysis.
 *
 * @package Zotpress
 */

// Global WordPress database object
global $wpdb;

/**
 * WordPress database class stub.
 */
class wpdb {
    public string $prefix = 'wp_';
    public int $insert_id = 0;
    public int $rows_affected = 0;
    public string $last_error = '';
    public ?array $last_result = null;

    /**
     * Prepare a SQL query for safe execution.
     *
     * @param string $query Query statement with sprintf()-like placeholders.
     * @param mixed  ...$args The array of variables to substitute.
     * @return string|null Sanitized query string.
     */
    public function prepare( string $query, mixed ...$args ): ?string {
        return $query;
    }

    /**
     * Retrieve one row from the database.
     *
     * @param string|null $query SQL query.
     * @param string      $output OBJECT, ARRAY_A, or ARRAY_N.
     * @param int         $y Row to return.
     * @return array|object|null
     */
    public function get_row( ?string $query = null, string $output = 'OBJECT', int $y = 0 ): mixed {
        return null;
    }

    /**
     * Retrieve one variable from the database.
     *
     * @param string|null $query SQL query.
     * @param int         $x Column of value to return.
     * @param int         $y Row of value to return.
     * @return string|null
     */
    public function get_var( ?string $query = null, int $x = 0, int $y = 0 ): ?string {
        return null;
    }

    /**
     * Retrieve an entire SQL result set from the database.
     *
     * @param string $query SQL query.
     * @param string $output OBJECT, ARRAY_A, or ARRAY_N.
     * @return array|null
     */
    public function get_results( string $query, string $output = 'OBJECT' ): ?array {
        return null;
    }

    /**
     * Perform a MySQL database query.
     *
     * @param string $query Database query.
     * @return int|bool
     */
    public function query( string $query ): int|bool {
        return 0;
    }

    /**
     * Insert a row into a table.
     *
     * @param string       $table Table name.
     * @param array        $data Data to insert.
     * @param array|string $format Data format.
     * @return int|false
     */
    public function insert( string $table, array $data, array|string $format = null ): int|false {
        return 1;
    }

    /**
     * Update a row in the table.
     *
     * @param string       $table Table name.
     * @param array        $data Data to update.
     * @param array        $where WHERE clause.
     * @param array|string $format Data format.
     * @param array|string $where_format WHERE format.
     * @return int|false
     */
    public function update( string $table, array $data, array $where, array|string $format = null, array|string $where_format = null ): int|false {
        return 1;
    }

    /**
     * Delete a row in the table.
     *
     * @param string       $table Table name.
     * @param array        $where WHERE clause.
     * @param array|string $where_format WHERE format.
     * @return int|false
     */
    public function delete( string $table, array $where, array|string $where_format = null ): int|false {
        return 1;
    }
}

$wpdb = new wpdb();
